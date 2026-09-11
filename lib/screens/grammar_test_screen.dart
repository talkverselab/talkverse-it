import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';
import 'grammar_lesson_screen.dart';

class _Q {
  final String ko;
  final String label;
  final String answer;
  final String rd;
  final List<String> choices;
  const _Q(this.ko, this.label, this.answer, this.rd, this.choices);
}

/// 문법 테스트 — 한국어 뜻을 보고 맞는 문장을 4개 중에서 고른다. 한 판 10문제.
class GrammarTestScreen extends StatefulWidget {
  final GrammarLesson lesson;
  const GrammarTestScreen({super.key, required this.lesson});

  @override
  State<GrammarTestScreen> createState() => _GrammarTestScreenState();
}

class _GrammarTestScreenState extends State<GrammarTestScreen> {
  static const _round = 10;
  final _rng = Random();
  List<_Q> _qs = [];
  int _i = 0;
  int _score = 0;
  String? _picked;
  final List<(_Q, String)> _wrong = [];

  @override
  void initState() {
    super.initState();
    _build();
  }

  void _build() {
    final pool = <(Map<String, dynamic>, Map)>[];
    for (final p in widget.lesson.patterns) {
      for (final ex in (p['examples'] as List? ?? const []).whereType<Map>()) {
        if ('${ex['tl'] ?? ''}'.isNotEmpty) pool.add((p, ex));
      }
    }
    pool.shuffle(_rng);
    final all = [for (final e in pool) '${e.$2['tl']}'];
    final qs = <_Q>[];
    for (final (p, ex) in pool.take(_round)) {
      final ans = '${ex['tl']}';
      final others = all.where((s) => s != ans).toList()..shuffle(_rng);
      final choices = [ans, ...others.take(3)]..shuffle(_rng);
      qs.add(_Q('${ex['ko'] ?? ''}', '${p['key'] ?? ''}', ans, '${ex['rd'] ?? ''}', choices));
    }
    setState(() {
      _qs = qs;
      _i = 0;
      _score = 0;
      _picked = null;
      _wrong.clear();
    });
  }

  void _pick(String c) {
    if (_picked != null) return;
    final q = _qs[_i];
    setState(() {
      _picked = c;
      if (c == q.answer) {
        _score++;
      } else {
        _wrong.add((q, c));
      }
    });
    TtsService.instance.speak(q.answer);
  }

  void _next() => setState(() {
        _i++;
        _picked = null;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(
        title: Text('${widget.lesson.title} · 테스트'),
        actions: const [KoReadingToggleAction()],
      ),
      body: _qs.length < 2
          ? const Center(
              child: Text('예문이 부족해 테스트를 만들 수 없습니다.',
                  style: TextStyle(color: AppColors.tintaLight)))
          : _i >= _qs.length
              ? _summary()
              : _question(),
    );
  }

  Widget _question() {
    final q = _qs[_i];
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            Text('${_i + 1} / ${_qs.length}',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.tintaLight)),
            const Spacer(),
            Text('맞힌 수 $_score',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.oliva)),
          ],
        ),
        const SizedBox(height: 18),
        Text(q.ko,
            style: const TextStyle(
                fontSize: 22, height: 1.4, fontWeight: FontWeight.w900, color: AppColors.tinta)),
        const SizedBox(height: 6),
        Text('패턴 · ${q.label}',
            style: const TextStyle(fontSize: 12, color: AppColors.tintaLight)),
        const SizedBox(height: 18),
        for (final c in q.choices) _choice(q, c),
        if (_picked != null) ...[
          if (q.rd.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: KoReadingText('정답 독음 · ${q.rd}',
                  style: const TextStyle(fontSize: 13, color: AppColors.rojoDeep)),
            ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.rojo),
              onPressed: _next,
              child: Text(_i == _qs.length - 1 ? '결과 보기' : '다음',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _choice(_Q q, String c) {
    final picked = _picked != null;
    final isAns = c == q.answer;
    final isMine = c == _picked;
    final Color border = !picked
        ? AppColors.tintaLight.withValues(alpha: 0.3)
        : isAns
            ? AppColors.oliva
            : (isMine ? AppColors.rojo : AppColors.tintaLight.withValues(alpha: 0.2));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _pick(c),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: picked && isAns ? AppColors.oliva.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: picked && (isAns || isMine) ? 2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(c,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.tinta)),
              ),
              if (picked && isAns) const Icon(Icons.check_circle, color: AppColors.oliva),
              if (picked && isMine && !isAns) const Icon(Icons.cancel, color: AppColors.rojo),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summary() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        Text('$_score / ${_qs.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppColors.rojo)),
        const SizedBox(height: 6),
        Text(_score == _qs.length ? '전부 맞혔어요!' : '틀린 문제를 다시 확인해 보세요',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.tintaLight)),
        const SizedBox(height: 20),
        for (final (q, mine) in _wrong)
          Card(
            color: Colors.white,
            child: ListTile(
              title: Text(q.answer, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${q.ko}\n내 답: $mine',
                  style: const TextStyle(fontSize: 12, height: 1.4)),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.volume_up, color: AppColors.rojo),
                onPressed: () => TtsService.instance.speak(q.answer),
              ),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rojo),
            onPressed: _build,
            child: const Text('다시 풀기', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }
}
