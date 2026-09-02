import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../main.dart';
import '../widgets/spanish_decor.dart';

/// 진행 — 턴 학습 / 동사 / 단어 집계.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _turnsTotal = 0;
  int _turnsLearned = 0;
  int _verbsTotal = 0;
  int _verbsKnown = 0;
  int _wordsTotal = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final turnsTotal = await appDb.turns.count().getSingle();
    final progress = await appDb.select(appDb.userProgress).get();
    final verbsTotal = await appDb.verbs.count().getSingle();
    final vp = await appDb.select(appDb.verbProgress).get();
    final wordsTotal = await appDb.words.count().getSingle();
    if (!mounted) return;
    setState(() {
      _turnsTotal = turnsTotal;
      _turnsLearned = progress.where((p) => p.learned).length;
      _verbsTotal = verbsTotal;
      _verbsKnown = vp.where((p) => p.known).length;
      _wordsTotal = wordsTotal;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(
        title: const Text('진행 · Progreso'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatCard(
                  label: '회화 턴',
                  badge: 'Ch',
                  done: _turnsLearned,
                  total: _turnsTotal,
                  color: AppColors.rojo,
                ),
                const SizedBox(height: 10),
                _StatCard(
                  label: '핵심 동사',
                  badge: 'V',
                  done: _verbsKnown,
                  total: _verbsTotal,
                  color: AppColors.irregular,
                ),
                const SizedBox(height: 10),
                _StatCard(
                  label: '빈도 단어 (DB)',
                  badge: 'W',
                  done: _wordsTotal,
                  total: _wordsTotal,
                  color: AppColors.oliva,
                ),
                const SizedBox(height: 24),
                const BandDivider(),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Poco a poco se va lejos',
                    style: TextStyle(color: AppColors.tintaLight, fontSize: 12, letterSpacing: 2),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String badge;
  final int done;
  final int total;
  final Color color;
  const _StatCard({
    required this.label,
    required this.badge,
    required this.done,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : done / total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            TileBadge(text: badge, size: 44, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 7,
                      backgroundColor: AppColors.calDeep,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$done / $total  (${(ratio * 100).toStringAsFixed(0)}%)',
                    style: const TextStyle(fontSize: 11, color: AppColors.tintaLight),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
