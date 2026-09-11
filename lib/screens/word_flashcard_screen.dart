import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../services/ko_reading.dart';
import '../services/memorized_store.dart';
import '../services/tts_service.dart';

class _Word {
  final String ko;
  final String tx;
  final String rd;
  final String ic;
  final String theme;
  const _Word(this.ko, this.tx, this.rd, this.ic, this.theme);
}

/// 단어 플래시카드 — 한국어·그림을 보고 대상어를 떠올린다.
/// "외웠어요"는 단어 메뉴의 외운 단어 체크(MemorizedStore)와 같은 기록을 쓴다.
class WordFlashcardScreen extends StatefulWidget {
  final String asset;
  const WordFlashcardScreen({super.key, this.asset = 'assets/data/vocab/travel_words.json'});

  @override
  State<WordFlashcardScreen> createState() => _WordFlashcardScreenState();
}

class _WordFlashcardScreenState extends State<WordFlashcardScreen> {
  final List<_Word> _all = [];
  List<_Word> _deck = [];
  final List<String> _themes = [];
  String? _theme; // null = 전체
  bool _hideMemorized = true;
  int _i = 0;
  bool _flipped = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await MemorizedStore.load();
    try {
      final d = json.decode(await rootBundle.loadString(widget.asset)) as Map<String, dynamic>;
      for (final t in (d['themes'] as List? ?? const []).whereType<Map>()) {
        final title = '${t['emoji'] ?? ''} ${t['title'] ?? ''}'.trim();
        _themes.add(title);
        for (final s in (t['sections'] as List? ?? const []).whereType<Map>()) {
          for (final w in (s['words'] as List? ?? const []).whereType<Map>()) {
            final tx = '${w['tx'] ?? ''}';
            if (tx.isEmpty) continue;
            _all.add(_Word('${w['ko'] ?? ''}', tx, '${w['rd'] ?? ''}', '${w['ic'] ?? ''}', title));
          }
        }
      }
    } catch (_) {}
    _rebuild();
    if (mounted) setState(() => _loading = false);
  }

  void _rebuild() {
    _deck = _all
        .where((w) => _theme == null || w.theme == _theme)
        .where((w) => !_hideMemorized || !MemorizedStore.contains(w.tx))
        .toList()
      ..shuffle(Random());
    _i = 0;
    _flipped = false;
  }

  Future<void> _answer(bool memorized) async {
    final w = _deck[_i];
    if (memorized && !MemorizedStore.contains(w.tx)) await MemorizedStore.toggle(w.tx);
    setState(() {
      _flipped = false;
      _i++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final memorized = _all.where((w) => MemorizedStore.contains(w.tx)).length;
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(
        title: const Text('단어 카드'),
        actions: [
          const KoReadingToggleAction(),
          IconButton(
            tooltip: _hideMemorized ? '외운 단어도 보기' : '외운 단어 빼기',
            icon: Icon(_hideMemorized ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() {
              _hideMemorized = !_hideMemorized;
              _rebuild();
            }),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _all.isEmpty
              ? const Center(
                  child: Text('아직 단어가 없습니다.', style: TextStyle(color: AppColors.tintaLight)))
              : Column(
                  children: [
                    SizedBox(
                      height: 46,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        children: [
                          _chip('전체', _theme == null, () => _theme = null),
                          for (final t in _themes) _chip(t, _theme == t, () => _theme = t),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Text(_deck.isEmpty ? '0 / 0' : '${(_i + 1).clamp(1, _deck.length)} / ${_deck.length}',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.tinta)),
                          const Spacer(),
                          Text('외움 $memorized / ${_all.length}',
                              style: const TextStyle(fontSize: 12, color: AppColors.oliva, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    Expanded(child: _i >= _deck.length ? _done() : _card()),
                  ],
                ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback set) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          selected: on,
          onSelected: (_) => setState(() {
            set();
            _rebuild();
          }),
        ),
      );

  Widget _card() {
    final w = _deck[_i];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_flipped) TtsService.instance.speak(w.tx);
                setState(() => _flipped = !_flipped);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _flipped ? AppColors.rojo : AppColors.gualda.withValues(alpha: 0.7), width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (w.ic.isNotEmpty) Text(w.ic, style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 12),
                    Text(w.ko,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.tinta)),
                    const SizedBox(height: 20),
                    if (_flipped) ...[
                      Text(w.tx,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.rojoDeep)),
                      if (w.rd.isNotEmpty)
                        KoReadingText(w.rd,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: AppColors.gualdaDeep)),
                      const SizedBox(height: 8),
                      IconButton(
                        icon: const Icon(Icons.volume_up, color: AppColors.rojo, size: 30),
                        onPressed: () => TtsService.instance.speak(w.tx),
                      ),
                    ] else
                      const Text('탭하면 정답', style: TextStyle(fontSize: 12, color: AppColors.tintaLight)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _btn('다시 볼래요', AppColors.gualdaDeep, () => _answer(false))),
              const SizedBox(width: 10),
              Expanded(child: _btn('외웠어요', AppColors.oliva, () => _answer(true))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, Color c, VoidCallback onTap) => SizedBox(
        height: 50,
        child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: c),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ),
      );

  Widget _done() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('이번 묶음 끝!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.tinta)),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.rojo),
              onPressed: () => setState(_rebuild),
              child: const Text('다시 섞어서 시작'),
            ),
          ],
        ),
      );
}
