import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';
import '../widgets/spanish_decor.dart';
import 'grammar_test_screen.dart';

/// 문법 강의 자산 — `assets/data/grammar/lessonN.json`
/// `{lesson, title, subtitle, stages:[{stage,title}],
///   patterns:[{id,key,label,explanation,stage,examples:[{tl,rd,ko}]}]}`
class GrammarLesson {
  final int number;
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> stages;
  final List<Map<String, dynamic>> patterns;
  const GrammarLesson(this.number, this.title, this.subtitle, this.stages, this.patterns);

  int get exampleCount =>
      patterns.fold(0, (n, p) => n + ((p['examples'] as List?)?.length ?? 0));

  static Future<List<GrammarLesson>> loadAll() async {
    final out = <GrammarLesson>[];
    for (var i = 1; i <= 20; i++) {
      try {
        final raw = await rootBundle.loadString('assets/data/grammar/lesson$i.json');
        final d = json.decode(raw) as Map<String, dynamic>;
        out.add(GrammarLesson(
          (d['lesson'] as num?)?.toInt() ?? i,
          d['title'] as String? ?? '문법 $i',
          d['subtitle'] as String? ?? '',
          [for (final s in (d['stages'] as List? ?? const [])) Map<String, dynamic>.from(s as Map)],
          [for (final p in (d['patterns'] as List? ?? const [])) Map<String, dynamic>.from(p as Map)],
        ));
      } catch (_) {
        break;
      }
    }
    return out;
  }
}

/// 문법 — 강의 목록.
class GrammarHubScreen extends StatefulWidget {
  const GrammarHubScreen({super.key});

  @override
  State<GrammarHubScreen> createState() => _GrammarHubScreenState();
}

class _GrammarHubScreenState extends State<GrammarHubScreen> {
  List<GrammarLesson>? _lessons;

  @override
  void initState() {
    super.initState();
    GrammarLesson.loadAll().then((l) {
      if (mounted) setState(() => _lessons = l);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lessons = _lessons;
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(title: const Text('문법')),
      body: lessons == null
          ? const Center(child: CircularProgressIndicator())
          : lessons.isEmpty
              ? const Center(
                  child: Text('아직 문법 강의가 없습니다.',
                      style: TextStyle(color: AppColors.tintaLight)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final l in lessons)
                      Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                          leading: TileBadge(text: '${l.number}', size: 40),
                          title: Text(l.title,
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(
                              '${l.subtitle.isEmpty ? '' : '${l.subtitle}\n'}'
                              '패턴 ${l.patterns.length} · 예문 ${l.exampleCount}',
                              style: const TextStyle(fontSize: 12, height: 1.4)),
                          trailing: IconButton(
                            tooltip: '테스트',
                            icon: const Icon(Icons.quiz, color: AppColors.rojo),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => GrammarTestScreen(lesson: l)),
                            ),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => GrammarLessonScreen(lesson: l)),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

/// 문법 강의 — 단계별 패턴 카드 + 예문(대상어·독음·뜻, 탭하면 발음).
class GrammarLessonScreen extends StatelessWidget {
  final GrammarLesson lesson;
  const GrammarLessonScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final stages = lesson.stages.isEmpty
        ? [<String, dynamic>{'stage': null, 'title': ''}]
        : lesson.stages;
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(
        title: Text(lesson.title),
        actions: [
          const KoReadingToggleAction(),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GrammarTestScreen(lesson: lesson)),
            ),
            icon: const Icon(Icons.quiz, color: Colors.white),
            label: const Text('테스트',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          for (final st in stages) ...[
            if ((st['title'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  TileBadge(text: '${st['stage']}', size: 26, color: AppColors.gualdaDeep),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(st['title'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, color: AppColors.tinta)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            for (final p in lesson.patterns)
              if (st['stage'] == null || p['stage'] == st['stage']) _PatternCard(p: p),
          ],
        ],
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  final Map<String, dynamic> p;
  const _PatternCard({required this.p});

  @override
  Widget build(BuildContext context) {
    final examples = (p['examples'] as List? ?? const []).whereType<Map>().toList();
    final expl = p['explanation'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gualda.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p['key'] as String? ?? '',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.rojoDeep)),
          if ((p['label'] as String? ?? '').isNotEmpty)
            Text(p['label'] as String,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.tinta)),
          if (expl != null && expl.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(expl,
                style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.tintaLight)),
          ],
          const SizedBox(height: 8),
          const BandDivider(height: 3),
          for (final ex in examples)
            InkWell(
              onTap: () => TtsService.instance.speak('${ex['tl'] ?? ''}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, right: 8),
                      child: Icon(Icons.volume_up, size: 18, color: AppColors.rojo),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText('${ex['tl'] ?? ''}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.tinta)),
                          if ('${ex['rd'] ?? ''}'.isNotEmpty)
                            KoReadingText('${ex['rd']}',
                                style: const TextStyle(fontSize: 13, color: AppColors.rojoDeep)),
                          Text('${ex['ko'] ?? ''}',
                              style: const TextStyle(fontSize: 13, color: AppColors.tintaLight)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
