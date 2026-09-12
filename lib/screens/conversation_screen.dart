import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../main.dart';
import '../widgets/spanish_decor.dart';
import 'episode_screen.dart';
import '../core/l10n.dart';

/// 회화 허브 — 레벨별 에피소드 목록 + 진행도.
class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  bool _loading = true;
  final Map<String, (int learned, int total)> _progress = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await EpisodeCatalog.instance.ensureLoaded();
    final turns = await appDb.select(appDb.turns).get();
    final progress = await appDb.select(appDb.userProgress).get();
    final learnedIds = progress.where((p) => p.learned).map((p) => p.turnId).toSet();
    _progress.clear();
    for (final meta in EpisodeCatalog.instance.all) {
      final epTurns = turns.where((t) => t.level == meta.level && t.episodeId == meta.id);
      final total = epTurns.length;
      final learned = epTurns.where((t) => learnedIds.contains(t.id)).length;
      _progress['${meta.level}/${meta.id}'] = (learned, total);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = EpisodeCatalog.instance;
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(title: Text(tr('회화 · Conversazione'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final level in EpisodeCatalog.levels) ...[
                  Row(
                    children: [
                      TileBadge(text: level, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        EpisodeCatalog.levelLabels[level] ?? level,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.tinta,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (catalog.forLevel(level).isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 36, bottom: 16),
                      child: Text(
                        tr('준비 중'),
                        style: TextStyle(color: AppColors.tintaLight, fontSize: 12),
                      ),
                    )
                  else
                    for (final meta in catalog.forLevel(level))
                      _EpisodeTile(
                        meta: meta,
                        progress: _progress['${meta.level}/${meta.id}'] ?? (0, 0),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EpisodeScreen(meta: meta)),
                          );
                          _load();
                        },
                      ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final EpisodeMeta meta;
  final (int, int) progress;
  final VoidCallback onTap;
  const _EpisodeTile({required this.meta, required this.progress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (learned, total) = progress;
    final ratio = total == 0 ? 0.0 : learned / total;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Text(meta.emoji, style: const TextStyle(fontSize: 26)),
        title: Text(
          '${meta.id.toUpperCase()} · ${meta.title}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 5,
                backgroundColor: AppColors.calDeep,
                color: ratio >= 1 ? AppColors.oliva : AppColors.rojo,
              ),
            ),
            const SizedBox(height: 4),
            Text('$learned / $total turn', style: const TextStyle(fontSize: 11)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
