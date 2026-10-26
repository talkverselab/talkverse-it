import 'package:flutter/material.dart';

/// 컬러 팔레트 — talkverse.uk 톤(2026-10-26).
///
/// 흰 바탕 + 남색 글자 + 인디고 포인트 하나, 그 밖의 색은 절제한다.
/// 이름(rojo·gualda·cal…)은 옛 국기 팔레트(스페인어 템플릿)에서 온 것이라
/// 화면 코드가 그대로 쓰고, 값만 사이트 토큰(`--ink`·`--body`·`--accent`…)에 맞췄다.
class AppColors {
  // 주색 — 사이트 `--accent` 인디고
  static const Color rojo = Color(0xFF635BFF);
  static const Color rojoDeep = Color(0xFF4B44D6); // `--accent-ink`
  static const Color rojoLight = Color(0xFFA9A4FF);

  // 옛 금색 자리 — 테두리는 사이트 `--line` 계열, 밝은 강조는 히어로 피치
  static const Color gualda = Color(0xFFDDE3EC);
  static const Color gualdaBright = Color(0xFFFFD39B);
  static const Color gualdaDeep = Color(0xFF6B7C93); // `--muted`

  // 글자 — `--ink` / `--body`
  static const Color tinta = Color(0xFF0A2540);
  static const Color tintaLight = Color(0xFF425466);

  // 바탕 — 흰색 / `--soft`
  static const Color cal = Color(0xFFFFFFFF);
  static const Color calDeep = Color(0xFFF6F9FC);

  // 보조 강조 — 차분한 청록(완료·학습됨)
  static const Color oliva = Color(0xFF0E7C8C);

  // 이탈리아어 카드색 — talkverse.uk 언어 카드의 `--c`
  static const Color italia = Color(0xFF3FA05A);

  // Mediterráneo (정보성 강조)
  static const Color mar = Color(0xFF1E6FA8);

  // 명사 성(gender) 시각화
  static const Color masc = Color(0xFF1E88E5); // el / -o
  static const Color fem = Color(0xFFE53935); // la / -a
  static const Color neutral = Color(0xFF8E8579); // 불변화·기타

  // 동사 활용군 (시각 학습용)
  static const Color ar = Color(0xFFE53935); // -ar
  static const Color er = Color(0xFFFB8C00); // -er
  static const Color ir = Color(0xFF43A047); // -ir
  static const Color irregular = Color(0xFF6A1B9A); // 불규칙

  // brand alias
  static const Color brand = rojo;
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.rojo,
        onPrimary: Colors.white,
        primaryContainer: AppColors.rojoLight,
        onPrimaryContainer: AppColors.tinta,
        secondary: AppColors.tintaLight,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.gualdaBright,
        onSecondaryContainer: AppColors.tinta,
        tertiary: AppColors.oliva,
        onTertiary: AppColors.cal,
        tertiaryContainer: const Color(0xFFCDEFF2),
        onTertiaryContainer: AppColors.tinta,
        error: const Color(0xFFB00020),
        onError: Colors.white,
        surface: AppColors.cal,
        onSurface: AppColors.tinta,
        surfaceContainerHighest: AppColors.calDeep,
        onSurfaceVariant: AppColors.tintaLight,
        outline: AppColors.gualdaDeep,
        outlineVariant: AppColors.gualda,
      ),
      scaffoldBackgroundColor: AppColors.cal,
      fontFamily: 'Pretendard',
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.tintaLight,
        displayColor: AppColors.tinta,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.cal,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.tinta,
        shape: Border(bottom: BorderSide(color: AppColors.gualda, width: 1)),
        titleTextStyle: TextStyle(
          color: AppColors.tinta,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cal,
        shadowColor: const Color(0x1A32325D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.gualda, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cal,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFFEFEEFE),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.rojo : AppColors.gualdaDeep,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.rojo : AppColors.gualdaDeep,
            size: 24,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.tinta,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.tinta,
          side: const BorderSide(color: AppColors.gualda),
          shape: const StadiumBorder(),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.calDeep,
        labelStyle: const TextStyle(color: AppColors.tinta, fontWeight: FontWeight.w600),
        side: const BorderSide(color: AppColors.gualda),
        shape: const StadiumBorder(),
        selectedColor: AppColors.rojo,
        secondaryLabelStyle: const TextStyle(color: AppColors.cal),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.gualda,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.rojo,
        textColor: AppColors.tinta,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.rojo,
        brightness: Brightness.dark,
      ),
      fontFamily: 'Pretendard',
    );
  }
}

/// 동사 활용군 색 — 'ar' | 'er' | 'ir' | 'irregular'
Color conjColor(String? group) {
  switch (group) {
    case 'ar':
      return AppColors.ar;
    case 'er':
      return AppColors.er;
    case 'ir':
      return AppColors.ir;
    case 'irregular':
      return AppColors.irregular;
    default:
      return AppColors.neutral;
  }
}

/// 명사 성 색 — 'm' | 'f'
Color genderColor(String? gender) {
  switch (gender) {
    case 'm':
      return AppColors.masc;
    case 'f':
      return AppColors.fem;
    default:
      return AppColors.neutral;
  }
}
