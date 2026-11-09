import '../core/embed_env.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/it_phonetics.dart';
import '../services/tts_service.dart';

/// 소리 칸 탭 → 발음 상세 시트(일본어앱 kana_sound_sheet 구조).
/// 열리면 1초 뒤 자동 재생, IPA·소리 나는 곳·조음 위치 그림·한국어 비교, 다시 듣기.
Future<void> showItSoundSheet(BuildContext context, {required ItSound sound, required Color color}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.washi,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => ItSoundSheet(sound: sound, color: color),
  );
}

class ItSoundSheet extends StatefulWidget {
  final ItSound sound;
  final Color color;
  const ItSoundSheet({super.key, required this.sound, required this.color});

  @override
  State<ItSoundSheet> createState() => _ItSoundSheetState();
}

class _ItSoundSheetState extends State<ItSoundSheet> {
  Timer? _autoPlay;
  bool _showChart = false;

  @override
  void initState() {
    super.initState();
    _autoPlay = Timer(const Duration(seconds: 1), _play);
  }

  void _play() => TtsService.instance.speak(widget.sound.say);

  @override
  void dispose() {
    _autoPlay?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sound;
    final color = widget.color;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scroll) => SafeArea(
        top: false,
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(20, 12, 20, 32 + bottomInset(context)),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.sumiLight.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 84, maxWidth: 160),
                  height: 84,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(s.label, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.rd, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
                      const SizedBox(height: 4),
                      Text('IPA [${s.ipa}]', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                    ],
                  ),
                ),
                IconButton(
                  iconSize: 44,
                  color: color,
                  tooltip: tr('다시 듣기'),
                  icon: const Icon(Icons.play_circle_fill),
                  onPressed: _play,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _section(tr('🔤 예시 낱말'), '${s.example} — ${s.exampleKo}', color),
            const SizedBox(height: 12),
            _section(tr('👄 소리 나는 곳 · 입 모양'), s.place, color),
            if (s.consonant) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => setState(() => _showChart = !_showChart),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(_showChart ? Icons.expand_less : Icons.expand_more, size: 18, color: color),
                      Text(tr('자음 조음 위치 그림 보기'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                    ],
                  ),
                ),
              ),
              if (_showChart) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(assetPath('assets/images/ipa/places_of_articulation.png'), fit: BoxFit.contain),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 12),
            _section(tr('🇰🇷 한국어와 비교'), trf('비슷한 소리: {0}\n\n{1}', [s.korSim, s.korDiff]), color),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.washiDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 13.5, height: 1.55, color: AppColors.sumi)),
        ],
      ),
    );
  }
}
