import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/dialogue_service.dart';
import '../services/tts_service.dart';
import '../services/word_service.dart';

/// 문장의 내용어(레마) 칩 — 단어장에 있는 말은 누르면 단어 시트, 없는 말은 회색(일본어앱 lemma_chips 를 옮김, 2026-11-04).
/// 같은 기본형은 한 번만. 단어장이 비어 있으면(2026-11-04 현재) 전부 회색 + 「단어장에 없는 말」.
class LemmaChips extends StatelessWidget {
  final DialogueTurn turn;
  final bool compact;
  const LemmaChips({super.key, required this.turn, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final lemmas = [for (final l in turn.lemmas) if (seen.add(l.base)) l];
    if (lemmas.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<Map<String, WordEntry>>(
      key: ValueKey('${turn.num}:${turn.tl}'),
      future: WordService.instance.byLemmas(lemmas.map((l) => l.base)),
      builder: (context, snap) {
        final found = snap.data ?? const <String, WordEntry>{};
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final l in lemmas)
              _Chip(
                label: l.base,
                gloss: found[l.base]?.gloss,
                compact: compact,
                onTap: found[l.base] == null ? null : () => showWordSheet(context, found[l.base]!),
              ),
            if (snap.connectionState == ConnectionState.done && found.isEmpty)
              Text(tr('단어장에 없는 말'), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String? gloss;
  final bool compact;
  final VoidCallback? onTap;
  const _Chip({required this.label, this.gloss, this.compact = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: compact ? 3 : 4),
        decoration: BoxDecoration(
          color: on ? AppColors.washi : AppColors.washiDeep,
          border: Border.all(color: on ? AppColors.beni.withValues(alpha: 0.7) : AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(fontSize: compact ? 12 : 13.5, fontWeight: FontWeight.w800, color: on ? AppColors.sumi : AppColors.muted)),
          if (gloss != null && gloss!.isNotEmpty) ...[
            const SizedBox(width: 5),
            Text(gloss!.split(RegExp(r'[,;·/]')).first.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: compact ? 10 : 11, color: AppColors.sumiLight)),
          ],
        ]),
      ),
    );
  }
}

/// 단어장 항목 시트 — 단어 · 품사·성 · 한국어 뜻 · 듣기.
Future<void> showWordSheet(BuildContext context, WordEntry e) => showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.washi,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset(ctx)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(e.word, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.sumi))),
            IconButton(onPressed: () => TtsService.instance.speak(e.word), icon: const Icon(Icons.volume_up, color: AppColors.beni, size: 28)),
          ]),
          if (e.pos != null || e.gender != null || e.rank != null)
            Text(
              [if (e.pos != null) e.pos!, if (e.gender != null) e.gender!, if (e.rank != null) '#${e.rank}'].join(' · '),
              style: const TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: 1),
            ),
          if (e.gloss != null && e.gloss!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(e.gloss!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.sumi, height: 1.4)),
          ],
        ]),
      ),
    );
