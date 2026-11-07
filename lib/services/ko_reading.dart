import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/l10n.dart';
import '../core/theme.dart';

/// 한글독음(발음 표기) 표시/숨김 전역 설정 — 모든 메뉴 공용. 기본 미표시(사용자 지시 2026-11-07, 일본어앱 후리가나와 같음).
/// (es 앱은 rd 필드가 이미 한글독음 데이터라 변환기 없이 표시만 제어)
class KoReadingPrefs {
  KoReadingPrefs._();

  static const _key = 'show_ko_reading_v2'; // 옛 키는 기본이 표시였다 — 새 기본을 모두에게 적용
  static final ValueNotifier<bool> show = ValueNotifier<bool>(false);

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    show.value = p.getBool(_key) ?? false;
  }

  static Future<void> toggle() async {
    show.value = !show.value;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, show.value);
  }
}

/// 앱바용 한글독음 토글 버튼 — 모든 메뉴 공통.
class KoReadingToggleAction extends StatelessWidget {
  const KoReadingToggleAction({super.key});

  /// 표시로 켤 때는 한 번 알린다.
  static Future<void> toggle(BuildContext context) async {
    await KoReadingPrefs.toggle();
    if (KoReadingPrefs.show.value && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(tr('힘들어도 한글 독음을 보지 않고 익혀보세요')),
          duration: const Duration(seconds: 3),
          backgroundColor: AppColors.sumi,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;
    return ValueListenableBuilder<bool>(
      valueListenable: KoReadingPrefs.show,
      builder: (context, on, _) {
        final color = on ? base : base.withValues(alpha: 0.35);
        return IconButton(
          tooltip: on ? tr('한글독음 숨기기') : tr('한글독음 표시'),
          onPressed: () => toggle(context),
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 1.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tr('한'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
                decoration: on ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 독음 텍스트 — 전역 설정이 꺼져 있으면 빈 위젯.
class KoReadingText extends StatelessWidget {
  const KoReadingText(
    this.reading, {
    super.key,
    this.style,
    this.textAlign,
  });

  final String reading;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: KoReadingPrefs.show,
      builder: (context, on, _) {
        if (!on) return const SizedBox.shrink();
        return Text(reading, textAlign: textAlign, style: style);
      },
    );
  }
}
