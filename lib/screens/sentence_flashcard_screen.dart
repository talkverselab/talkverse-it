import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../main.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';
import '../widgets/spanish_decor.dart';
import 'episode_screen.dart';
import '../core/platform.dart';
import '../core/l10n.dart';

enum _CardState { unknown, studying, known }

/// 문장 플래시카드 — 기본은 한국어 앞면 → 뒤집으면 대상어.
/// 방향·힌트 토글은 저장되고, 몰라요/공부중/알아요 평가는 학습 기록(DB)에 남는다.
class SentenceFlashcardScreen extends StatefulWidget {
  final String? level;
  final String? episodeId;
  final int initialIndex;
  final String title;

  const SentenceFlashcardScreen({
    super.key,
    this.level,
    this.episodeId,
    this.initialIndex = 0,
    this.title = '문장 카드',
  });

  @override
  State<SentenceFlashcardScreen> createState() =>
      _SentenceFlashcardScreenState();
}

class _SentenceFlashcardScreenState extends State<SentenceFlashcardScreen> {
  static const _kKoFirst = 'card_ko_first';
  static const _kShowHint = 'card_show_hint';

  List<TurnRow> _turns = [];
  final Map<int, _CardState> _state = {};
  int _index = 0;
  bool _flipped = false;
  bool _koFirst = true;
  bool _showHint = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _koFirst = prefs.getBool(_kKoFirst) ?? true;
    _showHint = prefs.getBool(_kShowHint) ?? true;
    await EpisodeCatalog.instance.ensureLoaded();

    final q = appDb.select(appDb.turns);
    if (widget.level != null) q.where((t) => t.level.equals(widget.level!));
    if (widget.episodeId != null) {
      q.where((t) => t.episodeId.equals(widget.episodeId!));
    }
    q.orderBy([(t) => OrderingTerm(expression: t.id)]);
    final turns = await q.get();

    final progress = await appDb.select(appDb.userProgress).get();
    final byId = {for (final p in progress) p.turnId: p};
    for (final t in turns) {
      final p = byId[t.id];
      _state[t.id] = p == null
          ? _CardState.unknown
          : p.learned
              ? _CardState.known
              : (p.reviewCount > 0 ? _CardState.studying : _CardState.unknown);
    }
    if (!mounted) return;
    setState(() {
      _turns = turns;
      _index = widget.initialIndex.clamp(0, turns.isEmpty ? 0 : turns.length - 1);
      _loading = false;
    });
  }

  Future<void> _rate(_CardState s) async {
    final t = _turns[_index];
    await appDb.into(appDb.userProgress).insertOnConflictUpdate(
          UserProgressCompanion(
            turnId: Value(t.id),
            learned: Value(s == _CardState.known),
            reviewCount: Value(s == _CardState.unknown ? 0 : 1),
            lastReviewed: Value(DateTime.now()),
          ),
        );
    setState(() => _state[t.id] = s);
    _go(1);
  }

  void _go(int d) {
    if (_turns.isEmpty) return;
    final next = _index + d;
    if (next < 0 || next >= _turns.length) return;
    setState(() {
      _index = next;
      _flipped = false;
    });
  }

  Future<void> _toggleDir() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _koFirst = !_koFirst;
      _flipped = false;
    });
    await prefs.setBool(_kKoFirst, _koFirst);
  }

  Future<void> _toggleHint() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _showHint = !_showHint);
    await prefs.setBool(_kShowHint, _showHint);
  }

  void _speak(TurnRow t) {
    final gender = EpisodeCatalog.instance
        .speaker(t.level, t.speaker)
        .gender;
    TtsService.instance.speakAs(t.es, gender: gender);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(
        title: Text(tr(widget.title)),
        actions: [
          const KoReadingToggleAction(),
          IconButton(
            tooltip: _showHint ? tr('힌트 끄기') : tr('힌트 켜기'),
            icon: Icon(_showHint ? Icons.lightbulb : Icons.lightbulb_outline),
            onPressed: _toggleHint,
          ),
          TextButton(
            onPressed: _toggleDir,
            child: Text(
              _koFirst ? tr('한→외') : tr('외→한'),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _turns.isEmpty
              ? _Empty(text: tr('아직 문장이 없습니다.\n회화 콘텐츠가 들어오면 여기서 연습할 수 있어요.'))
              : _body(),
    );
  }

  Widget _body() {
    final t = _turns[_index];
    final st = _state[t.id] ?? _CardState.unknown;
    final known = _state.values.where((s) => s == _CardState.known).length;
    final border = switch (st) {
      _CardState.known => AppColors.oliva,
      _CardState.studying => AppColors.gualda,
      _CardState.unknown => AppColors.tintaLight.withValues(alpha: 0.4),
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 20 + bottomInset(context)),
      child: Column(
        children: [
          Row(
            children: [
              Text('${_index + 1} / ${_turns.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.tinta)),
              const Spacer(),
              _StateChip(state: st),
              const SizedBox(width: 8),
              Text(trf('알아요 {0}', [known]),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.tintaLight)),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                final toAnswer = !_flipped;
                setState(() => _flipped = !_flipped);
                if (toAnswer) _speak(t);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 2),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _flipped ? tr('정답') : (_koFirst ? tr('한국어') : tr('대상어')),
                        style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: 2,
                            color: AppColors.tintaLight),
                      ),
                      const SizedBox(height: 14),
                      if (_flipped || !_koFirst) ...[
                        // 뒷면(정답) 또는 대상어 앞면
                        Text(t.es,
                            style: const TextStyle(
                                fontSize: 26,
                                height: 1.35,
                                fontWeight: FontWeight.w800,
                                color: AppColors.tinta)),
                        if ((t.rd ?? '').isNotEmpty &&
                            (_flipped || _showHint)) ...[
                          const SizedBox(height: 6),
                          KoReadingText(t.rd!,
                              style: const TextStyle(
                                  fontSize: 15, color: AppColors.rojoDeep)),
                        ],
                        if (_flipped) ...[
                          const SizedBox(height: 14),
                          Text(t.ko ?? '',
                              style: const TextStyle(
                                  fontSize: 16, color: AppColors.tintaLight)),
                        ],
                      ] else ...[
                        // 한국어 앞면
                        Text(t.ko ?? '',
                            style: const TextStyle(
                                fontSize: 24,
                                height: 1.4,
                                fontWeight: FontWeight.w800,
                                color: AppColors.tinta)),
                        if (_showHint && (t.rd ?? '').isNotEmpty) ...[
                          const SizedBox(height: 16),
                          KoReadingText('💡 ${t.rd}',
                              style: const TextStyle(
                                  fontSize: 14, color: AppColors.gualdaDeep)),
                        ],
                      ],
                      if (_flipped && (t.note ?? '').isNotEmpty) ...[
                        const SizedBox(height: 18),
                        const BandDivider(height: 4),
                        const SizedBox(height: 10),
                        Text('✎ ${t.note}',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.tintaLight)),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.volume_up,
                                color: AppColors.rojo),
                            onPressed: () => _speak(t),
                          ),
                          const Spacer(),
                          Text(_flipped ? tr('탭하면 앞면') : tr('탭하면 뒤집기'),
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.tintaLight)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _NavButton(
                  icon: Icons.chevron_left,
                  onTap: _index > 0 ? () => _go(-1) : null),
              const SizedBox(width: 8),
              Expanded(
                  child: _AnswerButton(
                      label: tr('몰라요'),
                      color: AppColors.rojo,
                      onTap: () => _rate(_CardState.unknown))),
              const SizedBox(width: 6),
              Expanded(
                  child: _AnswerButton(
                      label: tr('공부중'),
                      color: AppColors.gualdaDeep,
                      onTap: () => _rate(_CardState.studying))),
              const SizedBox(width: 6),
              Expanded(
                  child: _AnswerButton(
                      label: tr('알아요'),
                      color: AppColors.oliva,
                      onTap: () => _rate(_CardState.known))),
              const SizedBox(width: 8),
              _NavButton(
                  icon: Icons.chevron_right,
                  onTap: _index < _turns.length - 1 ? () => _go(1) : null),
            ],
          ),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  final _CardState state;
  const _StateChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      _CardState.known => (tr('알아요'), AppColors.oliva),
      _CardState.studying => (tr('공부중'), AppColors.gualdaDeep),
      _CardState.unknown => (tr('새 카드'), AppColors.tintaLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: onTap == null
                  ? AppColors.tintaLight.withValues(alpha: 0.2)
                  : AppColors.tinta),
        ),
        child: Icon(icon,
            color: onTap == null
                ? AppColors.tintaLight.withValues(alpha: 0.3)
                : AppColors.tinta),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AnswerButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14)),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  height: 1.6, color: AppColors.tintaLight)),
        ),
      );
}
