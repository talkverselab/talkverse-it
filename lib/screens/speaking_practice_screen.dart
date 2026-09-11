import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../main.dart';
import '../services/ko_reading.dart';
import '../services/speak_match.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../widgets/spanish_decor.dart';
import 'episode_screen.dart';

/// 단계별 제한 시간(초).
const _stageSeconds = {1: 10, 2: 5, 3: 2};

/// 말하기 연습 — 학습한 회화 목록. 탭하면 바로 테스트가 시작된다.
class SpeakingPracticeScreen extends StatefulWidget {
  const SpeakingPracticeScreen({super.key});

  @override
  State<SpeakingPracticeScreen> createState() => _SpeakingPracticeScreenState();
}

class _EpItem {
  final EpisodeMeta meta;
  final int total;
  final int learned;
  final int passed3;
  const _EpItem(this.meta, this.total, this.learned, this.passed3);
}

class _SpeakingPracticeScreenState extends State<SpeakingPracticeScreen> {
  static const _kStage = 'speak_stage';
  int _stage = 1;
  bool _loading = true;
  bool _onlyLearned = false;
  List<_EpItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _stage = prefs.getInt(_kStage) ?? 1;
    await EpisodeCatalog.instance.ensureLoaded();
    final turns = await appDb.select(appDb.turns).get();
    final progress = await appDb.select(appDb.userProgress).get();
    final learnedIds = {for (final p in progress) if (p.learned || p.reviewCount > 0) p.turnId};

    final items = <_EpItem>[];
    for (final meta in EpisodeCatalog.instance.all) {
      final ep = turns.where((t) => t.level == meta.level && t.episodeId == meta.id).toList();
      if (ep.isEmpty) continue;
      final learned = ep.where((t) => learnedIds.contains(t.id)).length;
      final passed3 = ep.where((t) => (prefs.getInt('speak_best_${t.id}') ?? 0) >= 3).length;
      items.add(_EpItem(meta, ep.length, learned, passed3));
    }
    final anyLearned = items.any((e) => e.learned > 0);
    if (!mounted) return;
    setState(() {
      _onlyLearned = anyLearned;
      _items = anyLearned ? items.where((e) => e.learned > 0).toList() : items;
      _loading = false;
    });
  }

  Future<void> _setStage(int s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kStage, s);
    setState(() => _stage = s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(title: const Text('말하기 연습')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('단계',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.tinta)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final s in _stageSeconds.keys) ...[
                      Expanded(
                        child: _StageChip(
                          label: '$s단계',
                          sub: '${_stageSeconds[s]}초',
                          selected: _stage == s,
                          onTap: () => _setStage(s),
                        ),
                      ),
                      if (s != 3) const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _onlyLearned
                      ? '학습한 회화 — 탭하면 바로 시작합니다'
                      : '전체 회화 — 회화에서 학습 체크하면 그 회화만 모아 보여 줍니다',
                  style: const TextStyle(fontSize: 12, color: AppColors.tintaLight),
                ),
                const SizedBox(height: 8),
                if (_items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('아직 회화가 없습니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.tintaLight)),
                  ),
                for (final e in _items)
                  Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Text(e.meta.emoji, style: const TextStyle(fontSize: 26)),
                      title: Text(e.meta.title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          '${e.meta.level} · ${e.total}문장 · 3단계 통과 ${e.passed3}',
                          style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.mic, color: AppColors.rojo),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SpeakingTestScreen(meta: e.meta, stage: _stage),
                          ),
                        );
                        _load();
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}

class _StageChip extends StatelessWidget {
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;
  const _StageChip({required this.label, required this.sub, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.rojo : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.rojo : AppColors.tintaLight.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppColors.tinta)),
            Text(sub,
                style: TextStyle(
                    fontSize: 11,
                    color: selected ? Colors.white70 : AppColors.tintaLight)),
          ],
        ),
      ),
    );
  }
}

// ─── 테스트 ────────────────────────────────────────────────────────────────

class _Result {
  final TurnRow turn;
  final bool pass;
  final String heard;
  const _Result(this.turn, this.pass, this.heard);
}

enum _Phase { ready, listening, judged, batchResult, done, error }

class SpeakingTestScreen extends StatefulWidget {
  final EpisodeMeta meta;
  final int stage;
  const SpeakingTestScreen({super.key, required this.meta, required this.stage});

  @override
  State<SpeakingTestScreen> createState() => _SpeakingTestScreenState();
}

class _SpeakingTestScreenState extends State<SpeakingTestScreen> {
  static const _kHint = 'speak_show_hint';
  static const _batch = 4;

  List<TurnRow> _turns = [];
  int _i = 0;
  _Phase _phase = _Phase.ready;
  String _heard = '';
  bool _pass = false;
  bool _showHint = false;
  int _left = 0;
  final List<_Result> _results = [];
  Timer? _timer;
  Timer? _delay;
  bool _disposed = false;
  String? _error;

  int get _seconds => _stageSeconds[widget.stage] ?? 10;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _delay?.cancel();
    SpeechService.instance.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _showHint = prefs.getBool(_kHint) ?? false;
    final q = appDb.select(appDb.turns)
      ..where((t) => t.level.equals(widget.meta.level) & t.episodeId.equals(widget.meta.id))
      ..orderBy([(t) => OrderingTerm(expression: t.num)]);
    _turns = await q.get();
    if (!mounted) return;
    setState(() {});
    if (_turns.isEmpty) return;
    final ok = await SpeechService.instance.init();
    if (!ok) {
      setState(() {
        _phase = _Phase.error;
        _error = '음성 인식을 쓸 수 없습니다. 마이크 권한과 Google 음성 인식 설치를 확인해 주세요.';
      });
      return;
    }
    _startTurn();
  }

  void _startTurn() {
    if (_disposed) return;
    setState(() {
      _phase = _Phase.ready;
      _heard = '';
      _pass = false;
      _left = _seconds;
    });
    _delay = Timer(const Duration(milliseconds: 1200), _listen);
  }

  Future<void> _listen() async {
    if (_disposed) return;
    final target = _turns[_i].es;
    final started = await SpeechService.instance.listen(
      maxFor: Duration(seconds: _seconds + 2),
      onResult: (words, isFinal) {
        if (_disposed || _phase != _Phase.listening) return;
        setState(() => _heard = words);
        if (SpeakMatch.pass(target, words)) _judge(true);
      },
    );
    if (!started) {
      setState(() {
        _phase = _Phase.error;
        _error = SpeechService.instance.lastError ?? '녹음을 시작하지 못했습니다.';
      });
      return;
    }
    setState(() => _phase = _Phase.listening);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (_disposed) return t.cancel();
      if (_phase != _Phase.listening) return t.cancel();
      setState(() => _left--);
      if (_left <= 0) {
        t.cancel();
        await SpeechService.instance.stop();
        // 최종 결과가 늦게 올 수 있어 잠깐 기다린다.
        await Future.delayed(const Duration(milliseconds: 1200));
        if (_phase == _Phase.listening) _judge(SpeakMatch.pass(target, _heard));
      }
    });
  }

  Future<void> _judge(bool pass) async {
    if (_phase != _Phase.listening) return;
    _timer?.cancel();
    await SpeechService.instance.cancel();
    final turn = _turns[_i];
    if (pass) {
      final prefs = await SharedPreferences.getInstance();
      final key = 'speak_best_${turn.id}';
      if ((prefs.getInt(key) ?? 0) < widget.stage) {
        await prefs.setInt(key, widget.stage);
      }
    }
    _results.add(_Result(turn, pass, _heard));
    if (_disposed) return;
    setState(() {
      _pass = pass;
      _phase = _Phase.judged;
    });
    _delay = Timer(const Duration(milliseconds: 900), _next);
  }

  void _next() {
    if (_disposed) return;
    final last = _i >= _turns.length - 1;
    if (last) {
      setState(() => _phase = _Phase.done);
    } else if ((_i + 1) % _batch == 0) {
      setState(() => _phase = _Phase.batchResult);
    } else {
      _i++;
      _startTurn();
    }
  }

  void _continue() {
    _i++;
    _startTurn();
  }

  void _restart() {
    _results.clear();
    _i = 0;
    _startTurn();
  }

  Future<void> _toggleHint() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _showHint = !_showHint);
    await prefs.setBool(_kHint, _showHint);
  }

  void _say(TurnRow t) {
    final g = EpisodeCatalog.instance.speaker(t.level, t.speaker).gender;
    TtsService.instance.speakAs(t.es, gender: g);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(
        title: Text('${widget.meta.title} · ${widget.stage}단계'),
        actions: [
          const KoReadingToggleAction(),
          IconButton(
            tooltip: '힌트',
            icon: Icon(_showHint ? Icons.lightbulb : Icons.lightbulb_outline),
            onPressed: _toggleHint,
          ),
        ],
      ),
      body: _turns.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : switch (_phase) {
              _Phase.error => _message(_error ?? '오류'),
              _Phase.batchResult => _resultView(
                  _results.sublist(_results.length - _batch.clamp(0, _results.length)),
                  button: '계속',
                  onTap: _continue),
              _Phase.done => _resultView(_results,
                  button: '처음부터 다시', onTap: _restart, summary: true),
              _ => _testView(),
            },
    );
  }

  Widget _message(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text, textAlign: TextAlign.center, style: const TextStyle(height: 1.6)),
        ),
      );

  Widget _testView() {
    final t = _turns[_i];
    final judged = _phase == _Phase.judged;
    final color = judged ? (_pass ? AppColors.oliva : AppColors.rojo) : AppColors.tinta;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${_i + 1} / ${_turns.length}',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.tintaLight)),
          const SizedBox(height: 24),
          Text(t.ko ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, height: 1.4, fontWeight: FontWeight.w800, color: AppColors.tinta)),
          const SizedBox(height: 14),
          if (_showHint || judged) ...[
            Text(t.es,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: AppColors.rojoDeep, fontWeight: FontWeight.w700)),
            if ((t.rd ?? '').isNotEmpty)
              KoReadingText(t.rd!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.gualdaDeep)),
          ],
          const Spacer(),
          Icon(
            judged ? (_pass ? Icons.check_circle : Icons.cancel) : Icons.mic,
            size: 72,
            color: _phase == _Phase.listening ? AppColors.rojo : color,
          ),
          const SizedBox(height: 8),
          Text(
            switch (_phase) {
              _Phase.ready => '곧 녹음합니다…',
              _Phase.listening => '말해 보세요 · $_left초',
              _Phase.judged => _pass ? 'PASS' : 'FAIL',
              _ => '',
            },
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 10),
          Text(_heard.isEmpty ? ' ' : '「$_heard」',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.tintaLight)),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _resultView(List<_Result> list,
      {required String button, required VoidCallback onTap, bool summary = false}) {
    final passed = list.where((r) => r.pass).length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            summary ? '전체 결과 · $passed / ${list.length}' : '결과 · $passed / ${list.length}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.tinta),
          ),
        ),
        const BandDivider(height: 4),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final r in list)
                Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: Icon(r.pass ? Icons.check_circle : Icons.cancel,
                        color: r.pass ? AppColors.oliva : AppColors.rojo),
                    title: Text(r.turn.es, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${r.turn.ko ?? ''}\n인식: ${r.heard.isEmpty ? '(없음)' : r.heard}',
                        style: const TextStyle(fontSize: 12, height: 1.4)),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.volume_up, color: AppColors.rojo),
                      onPressed: () => _say(r.turn),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.rojo),
              onPressed: onTap,
              child: Text(button, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }
}
