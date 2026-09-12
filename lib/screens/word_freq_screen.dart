import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../main.dart';
import '../services/tts_service.dart';
import '../core/platform.dart';
import '../core/l10n.dart';

/// 빈도 단어 — rank 순 목록 + 검색 + 성(gender) 색.
class WordFreqScreen extends StatefulWidget {
  const WordFreqScreen({super.key});

  @override
  State<WordFreqScreen> createState() => _WordFreqScreenState();
}

class _WordFreqScreenState extends State<WordFreqScreen> {
  List<WordRow> _words = const [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final words = await (appDb.select(appDb.words)
          ..orderBy([(w) => OrderingTerm.asc(w.rank)]))
        .get();
    if (mounted) setState(() => _words = words);
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty
        ? _words
        : _words
            .where((w) =>
                w.word.toLowerCase().contains(q) ||
                (w.meaningKo ?? '').contains(q))
            .toList();
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(title: Text(trf('빈도 단어 · {0}', [_words.length]))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: tr('단어 / 뜻 검색'),
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: _words.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(12, 4, 12, 80 + bottomInset(context)),
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final w = shown[i];
                      final gc = genderColor(w.gender);
                      return ListTile(
                        dense: true,
                        onTap: () => TtsService.instance.speak(w.word),
                        leading: SizedBox(
                          width: 36,
                          child: Text(
                            '${w.rank}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppColors.tintaLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            if (w.gender != null) ...[
                              Text(
                                w.gender == 'm' ? 'el' : 'la',
                                style: TextStyle(color: gc, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              w.word,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            if (w.pos != null)
                              Text(
                                w.pos!,
                                style: const TextStyle(fontSize: 10, color: AppColors.tintaLight),
                              ),
                          ],
                        ),
                        subtitle: Text(w.meaningKo ?? ''),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (w.cefr != null)
                              Text(w.cefr!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.mar)),
                            if (w.region != null)
                              Text(w.region!, style: const TextStyle(fontSize: 10, color: AppColors.tintaLight)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
