import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/italian_hints.dart';
import '../services/tts_service.dart';

/// 시안 it-01 이탈리아어 칸 — 캡션 글자. 동사·성·수 데이터가 없으면(지금) 그냥 [Text] 와 똑같이 그린다.
/// 데이터가 있으면 낱말마다 누를 수 있고(동사 → 활용 표), 명사·형용사 밑에 성·수 색 점을 찍는다.
class HintText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final bool showGender;
  final ValueChanged<String> onWord;
  const HintText({super.key, required this.text, required this.style, required this.showGender, required this.onWord});

  @override
  Widget build(BuildContext context) {
    final h = ItalianHints.instance;
    if (!h.hasVerbs && !(showGender && h.hasGender)) return Text(text, style: style);
    // 낱말과 그 사이(공백·문장부호)를 번갈아 나눈다
    final parts = RegExp(r"[\p{L}\p{N}]+|[^\p{L}\p{N}]+", unicode: true).allMatches(text).map((m) => m.group(0)!).toList();
    return Wrap(crossAxisAlignment: WrapCrossAlignment.start, children: [
      for (final p in parts)
        if (!RegExp(r'^[\p{L}\p{N}]', unicode: true).hasMatch(p))
          Text(p, style: style)
        else
          _Word(word: p, style: style, isVerb: h.verbOf(p) != null, gender: showGender ? h.genderOf(p) : null, onTap: () => onWord(p)),
    ]);
  }
}

class _Word extends StatelessWidget {
  final String word;
  final TextStyle style;
  final bool isVerb;
  final String? gender;
  final VoidCallback onTap;
  const _Word({required this.word, required this.style, required this.isVerb, required this.gender, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Text(word, style: isVerb ? style.copyWith(decoration: TextDecoration.underline, decorationColor: AppColors.beni, decorationStyle: TextDecorationStyle.dotted) : style);
    final col = Column(mainAxisSize: MainAxisSize.min, children: [t, if (gender != null) GenderDots(gender: gender!)]);
    return isVerb ? GestureDetector(onTap: onTap, child: col) : col;
  }
}

/// 성·수 색 점 — 남성 단수 남색 한 점, 여성 단수 테라코타 한 점, 복수는 두 점(시안 it-01).
class GenderDots extends StatelessWidget {
  final String gender; // m | f | mp | fp
  const GenderDots({super.key, required this.gender});

  static const _terracotta = Color(0xFFC0613B);

  @override
  Widget build(BuildContext context) {
    final c = gender.startsWith('f') ? _terracotta : AppColors.sumi;
    final n = gender.endsWith('p') ? 2 : 1;
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < n; i++)
          Container(width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      ]),
    );
  }
}

/// 동사 활용 표(현재형 6인칭) — 지금 쓰인 인칭을 올리브로 강조, 🔊 로 여섯 형태 듣기. 넓은 칸은 컷 아래, 좁은 칸은 아래 시트.
class VerbTablePanel extends StatelessWidget {
  final VerbForms verb;
  final int person;
  final String gender;
  final VoidCallback? onClose;
  const VerbTablePanel({super.key, required this.verb, required this.person, required this.gender, this.onClose});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(color: AppColors.washi, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14), boxShadow: kCardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Text(trf('동사: {0}', [verb.infinitive]), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sumi)),
            if (verb.ko.isNotEmpty) ...[
              const SizedBox(width: 8),
              Flexible(child: Text(verb.ko, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.muted))),
            ],
            const Spacer(),
            IconButton(
              tooltip: tr('여섯 형태 듣기'),
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.volume_up_outlined, size: 18, color: AppColors.beni),
              onPressed: () => TtsService.instance.speakAs([for (var i = 0; i < 6; i++) '${ItalianHints.persons[i]} ${verb.present[i]}'].join(', '), gender: gender),
            ),
            if (onClose != null) IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.close, size: 18, color: AppColors.muted), onPressed: onClose),
          ]),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisExtent: 30, crossAxisSpacing: 8, mainAxisSpacing: 4),
            itemCount: 6,
            itemBuilder: (context, i) {
              final on = i == person;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(color: on ? AppColors.beni.withValues(alpha: 0.12) : Colors.transparent, border: Border.all(color: on ? AppColors.beni : AppColors.line), borderRadius: BorderRadius.circular(8)),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '${ItalianHints.persons[i]}  ', style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                    TextSpan(text: verb.present[i], style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: on ? AppColors.beniDeep : AppColors.sumi)),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ]),
      ),
    );
  }
}

/// 폰·좁은 칸: 동사 활용 표를 아래 시트로.
class VerbTableSheet {
  static Future<void> show(BuildContext context, VerbForms verb, int person, {required String gender}) => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset(ctx)),
          child: VerbTablePanel(verb: verb, person: person, gender: gender),
        ),
      );
}
