import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../main.dart';
import '../services/tts_service.dart';
import '../widgets/spanish_decor.dart';
import '../core/platform.dart';
import '../core/l10n.dart';

const _persons = ['io', 'tu', 'lui/lei', 'noi', 'voi', 'loro'];

/// 동사 활용 — 핵심 동사 목록 + 현재/단순과거 표.
class VerbScreen extends StatefulWidget {
  const VerbScreen({super.key});

  @override
  State<VerbScreen> createState() => _VerbScreenState();
}

class _VerbScreenState extends State<VerbScreen> {
  List<VerbRow> _verbs = const [];
  Set<String> _known = {};
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final verbs = await (appDb.select(appDb.verbs)
          ..orderBy([(v) => OrderingTerm.asc(v.rank)]))
        .get();
    final progress = await appDb.select(appDb.verbProgress).get();
    if (!mounted) return;
    setState(() {
      _verbs = verbs;
      _known = progress.where((p) => p.known).map((p) => p.infinitive).toSet();
    });
  }

  Future<void> _toggleKnown(VerbRow v) async {
    final now = !_known.contains(v.infinitive);
    await appDb.into(appDb.verbProgress).insertOnConflictUpdate(
          VerbProgressCompanion(
            infinitive: Value(v.infinitive),
            known: Value(now),
            lastReviewed: Value(DateTime.now()),
          ),
        );
    setState(() {
      if (now) {
        _known.add(v.infinitive);
      } else {
        _known.remove(v.infinitive);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shown = _filter == 'all'
        ? _verbs
        : _verbs.where((v) => v.group == _filter).toList();
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(title: Text(tr('동사 활용 · Coniugazione'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                for (final g in ['all', 'ar', 'er', 'ir', 'irregular']) ...[
                  ChoiceChip(
                    label: Text(g == 'all' ? tr('전체') : (g == 'irregular' ? tr('불규칙') : '-$g')),
                    selected: _filter == g,
                    onSelected: (_) => setState(() => _filter = g),
                    selectedColor: conjColor(g == 'all' ? null : g),
                    labelStyle: TextStyle(
                      color: _filter == g ? AppColors.cal : AppColors.tinta,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          Expanded(
            child: _verbs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(12, 4, 12, 80 + bottomInset(context)),
                    itemCount: shown.length,
                    itemBuilder: (context, i) => _VerbCard(
                      verb: shown[i],
                      known: _known.contains(shown[i].infinitive),
                      onToggleKnown: () => _toggleKnown(shown[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _VerbCard extends StatelessWidget {
  final VerbRow verb;
  final bool known;
  final VoidCallback onToggleKnown;
  const _VerbCard({required this.verb, required this.known, required this.onToggleKnown});

  List<String> _forms(String? jsonStr) {
    if (jsonStr == null) return const [];
    return (json.decode(jsonStr) as List).map((e) => '$e').toList();
  }

  @override
  Widget build(BuildContext context) {
    final color = conjColor(verb.group);
    final present = _forms(verb.presentJson);
    final preterite = _forms(verb.preteriteJson);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: TileBadge(
          text: verb.group == 'irregular' ? '!' : verb.group,
          size: 36,
          color: color,
        ),
        title: Row(
          children: [
            Text(
              verb.infinitive,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(width: 8),
            if (known) const Icon(Icons.check_circle, size: 16, color: AppColors.oliva),
          ],
        ),
        subtitle: Text(verb.meaningKo ?? '', style: const TextStyle(fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.volume_up_outlined),
          onPressed: () => TtsService.instance.speak(verb.infinitive),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                _ConjTable(title: 'Presente', forms: present, color: color),
                if (preterite.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ConjTable(title: 'Pretérito', forms: preterite, color: color),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onToggleKnown,
                    icon: Icon(known ? Icons.undo : Icons.check),
                    label: Text(known ? tr('아는 동사 해제') : tr('아는 동사')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConjTable extends StatelessWidget {
  final String title;
  final List<String> forms;
  final Color color;
  const _ConjTable({required this.title, required this.forms, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: color.withValues(alpha: 0.12),
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 12, letterSpacing: 1),
            ),
          ),
          for (var i = 0; i < forms.length && i < _persons.length; i++)
            InkWell(
              onTap: () => TtsService.instance.speak(forms[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        _persons[i],
                        style: const TextStyle(fontSize: 12, color: AppColors.tintaLight),
                      ),
                    ),
                    Text(
                      forms[i],
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
