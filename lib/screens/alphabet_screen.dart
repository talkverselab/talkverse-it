import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/it_phonetics.dart';
import '../services/tts_service.dart';
import '../widgets/it_sound_sheet.dart';

/// 알파벳과 발음 — 일본어앱 「50음도와 발음」 구조(2026-11-08): 묶음 칩 + 격자 + 한글 보조 표기 토글, 칸 탭 = 발음 상세.
class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});

  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

const _groupColors = [AppColors.beni, AppColors.mar, AppColors.rojoDeep, AppColors.oliva, AppColors.er, AppColors.irregular];

class _AlphabetScreenState extends State<AlphabetScreen> {
  int _group = 0;
  bool _showRd = true;

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = kItSoundGroups[_group];
    final color = _groupColors[_group % _groupColors.length];
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('알파벳과 발음'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(tr('탭하면 발음·IPA 상세'), style: const TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 1)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: tr('한글 표기'),
            icon: Text('가', style: TextStyle(fontWeight: FontWeight.w900, color: _showRd ? AppColors.beni : AppColors.sumiLight)),
            onPressed: () => setState(() => _showRd = !_showRd),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: kItSoundGroups.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final sel = i == _group;
                final c = _groupColors[i % _groupColors.length];
                return ChoiceChip(
                  label: Text(tr(kItSoundGroups[i].name)),
                  selected: sel,
                  onSelected: (_) => setState(() => _group = i),
                  selectedColor: c,
                  labelStyle: TextStyle(color: sel ? Colors.white : c, fontWeight: FontWeight.w800, fontSize: 12),
                  side: BorderSide(color: c),
                  backgroundColor: AppColors.washi,
                  showCheckmark: false,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(tr(g.hint), style: const TextStyle(fontSize: 12.5, color: AppColors.sumiLight, height: 1.4)),
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              final wide = g.sounds.any((s) => s.label.length > 4);
              final cols = ((box.maxWidth - 24) / (wide ? 150 : 96)).floor().clamp(2, 8);
              return GridView.builder(
                padding: EdgeInsets.fromLTRB(12, 4, 12, 24 + bottomInset(context)),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: wide ? 1.7 : 1.05),
                itemCount: g.sounds.length,
                itemBuilder: (context, i) => _cell(g.sounds[i], color),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _cell(ItSound s, Color color) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => showItSoundSheet(context, sound: s, color: color),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.washi,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.6)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.10), blurRadius: 4, offset: const Offset(1, 2))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(s.label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.sumi, height: 1.1)),
            ),
            if (_showRd)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(s.rd, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }
}
