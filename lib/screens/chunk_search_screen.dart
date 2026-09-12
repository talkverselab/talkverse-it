import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/chunk_index_service.dart';
import '../services/ko_reading.dart';
import '../services/speak_match.dart';
import '../services/tts_service.dart';
import '../widgets/spanish_decor.dart';
import '../core/platform.dart';
import '../core/l10n.dart';

/// 청크 검색 — 대상어 단어·구, 한국어 뜻, 한글 독음으로 전 문장을 찾는다.
class ChunkSearchScreen extends StatefulWidget {
  const ChunkSearchScreen({super.key});

  @override
  State<ChunkSearchScreen> createState() => _ChunkSearchScreenState();
}

class _ChunkSearchScreenState extends State<ChunkSearchScreen> {
  final _ctrl = TextEditingController();
  bool _loading = true;
  List<ChunkHit> _hits = [];
  List<String> _top = [];

  @override
  void initState() {
    super.initState();
    ChunkIndexService.instance.ensureLoaded().then((_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _top = ChunkIndexService.instance.topWords(24);
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _search(String q) =>
      setState(() => _hits = ChunkIndexService.instance.search(q));

  @override
  Widget build(BuildContext context) {
    final svc = ChunkIndexService.instance;
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(
        title: Text(tr('청크 검색')),
        actions: const [KoReadingToggleAction()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _ctrl,
                    onChanged: _search,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: tr('단어·구 또는 한국어 뜻으로 검색'),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _ctrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _ctrl.clear();
                                _search('');
                              },
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(trf('문장 {0}개에서 찾습니다', [svc.all.length]),
                      style: const TextStyle(fontSize: 11, color: AppColors.tintaLight)),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: _ctrl.text.trim().isEmpty
                      ? _suggest()
                      : _hits.isEmpty
                          ? Center(
                              child: Text(tr('찾는 청크가 없습니다'),
                                  style: TextStyle(color: AppColors.tintaLight)))
                          : ListView(
                              padding: EdgeInsets.fromLTRB(16, 4, 16, 24 + bottomInset(context)),
                              children: [for (final h in _hits) _HitCard(hit: h, query: _ctrl.text)],
                            ),
                ),
              ],
            ),
    );
  }

  Widget _suggest() {
    if (_top.isEmpty) {
      return Center(
          child: Text(tr('아직 검색할 문장이 없습니다'),
              style: TextStyle(color: AppColors.tintaLight)));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(tr('자주 나오는 단어'),
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.tinta)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final w in _top)
              ActionChip(
                label: Text(w),
                backgroundColor: Colors.white,
                onPressed: () {
                  _ctrl.text = w;
                  _search(w);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _HitCard extends StatefulWidget {
  final ChunkHit hit;
  final String query;
  const _HitCard({required this.hit, required this.query});

  @override
  State<_HitCard> createState() => _HitCardState();
}

class _HitCardState extends State<_HitCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.hit;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gualda.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(h.chunk,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.rojoDeep)),
            subtitle: Text(trf('문장 {0}개', [h.sentences.length]),
                style: const TextStyle(fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.volume_up, color: AppColors.rojo),
                  onPressed: () => TtsService.instance.speak(h.chunk),
                ),
                Icon(_open ? Icons.expand_less : Icons.expand_more),
              ],
            ),
            onTap: () => setState(() => _open = !_open),
          ),
          if (_open) ...[
            const BandDivider(height: 3),
            for (final s in h.sentences.take(30)) _SentenceRow(s: s, chunk: h.chunk),
          ],
        ],
      ),
    );
  }
}

class _SentenceRow extends StatelessWidget {
  final IndexedSentence s;
  final String chunk;
  const _SentenceRow({required this.s, required this.chunk});

  /// 청크와 같은 단어들을 굵게.
  List<TextSpan> _spans() {
    final target = SpeakMatch.words(chunk);
    final re = RegExp(r"([\p{L}\p{M}\p{N}'’-]+)|([^\p{L}\p{M}\p{N}'’-]+)", unicode: true);
    return [
      for (final m in re.allMatches(s.tl))
        TextSpan(
          text: m.group(0),
          style: m.group(1) != null && target.contains(SpeakMatch.words(m.group(1)!).join())
              ? const TextStyle(color: AppColors.rojo, fontWeight: FontWeight.w900)
              : null,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => TtsService.instance.speakAs(s.tl, gender: s.gender),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2, right: 8),
              child: Icon(Icons.volume_up, size: 16, color: AppColors.rojo),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(TextSpan(
                      style: const TextStyle(fontSize: 15, color: AppColors.tinta),
                      children: _spans())),
                  if (s.rd.isNotEmpty)
                    KoReadingText(s.rd,
                        style: const TextStyle(fontSize: 12, color: AppColors.rojoDeep)),
                  Text(s.ko, style: const TextStyle(fontSize: 12, color: AppColors.tintaLight)),
                  Text(s.source, style: const TextStyle(fontSize: 10, color: AppColors.gualdaDeep)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
