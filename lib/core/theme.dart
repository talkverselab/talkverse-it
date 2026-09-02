import 'package:flutter/material.dart';

/// Italia 컬러 팔레트 — 국기 verde·rosso (식별자는 es 템플릿 유지) + 석회벽 백색·올리브·지중해 청색
class AppColors {
  // 主色 — Verde (국기 초록; 식별자 rojo는 템플릿 유지)
  static const Color rojo = Color(0xFF008C45);
  static const Color rojoDeep = Color(0xFF00602F);
  static const Color rojoLight = Color(0xFF33A56A);

  // 副色 — Rosso (국기 빨강; 식별자 gualda는 템플릿 유지)
  static const Color gualda = Color(0xFFCD212A);
  static const Color gualdaBright = Color(0xFFE8535B);
  static const Color gualdaDeep = Color(0xFF96181F);

  // Tinta (잉크, 본문 텍스트)
  static const Color tinta = Color(0xFF1F1A17);
  static const Color tintaLight = Color(0xFF5A4F48);

  // Cal (석회 벽, 부드러운 미색 배경)
  static const Color cal = Color(0xFFFBF5E6);
  static const Color calDeep = Color(0xFFF1E6C8);

  // Oliva (보조 강조)
  static const Color oliva = Color(0xFF6B8E23);

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
        onPrimary: AppColors.cal,
        primaryContainer: AppColors.rojoLight,
        onPrimaryContainer: AppColors.tinta,
        secondary: AppColors.gualda,
        onSecondary: AppColors.tinta,
        secondaryContainer: AppColors.gualdaBright,
        onSecondaryContainer: AppColors.tinta,
        tertiary: AppColors.oliva,
        onTertiary: AppColors.cal,
        tertiaryContainer: const Color(0xFFD6E4B0),
        onTertiaryContainer: AppColors.tinta,
        error: const Color(0xFFB00020),
        onError: Colors.white,
        surface: AppColors.cal,
        onSurface: AppColors.tinta,
        surfaceContainerHighest: AppColors.calDeep,
        onSurfaceVariant: AppColors.tintaLight,
        outline: AppColors.gualdaDeep,
        outlineVariant: const Color(0xFFDCCDA4),
      ),
      scaffoldBackgroundColor: AppColors.cal,
      fontFamily: 'Pretendard',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.rojo,
        foregroundColor: AppColors.cal,
        titleTextStyle: TextStyle(
          color: AppColors.cal,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.gualda, width: 0.8),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.tinta,
        indicatorColor: AppColors.rojo,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.gualdaBright : AppColors.calDeep,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.cal : AppColors.calDeep,
            size: 24,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.calDeep,
        labelStyle: const TextStyle(color: AppColors.tinta, fontWeight: FontWeight.w600),
        side: const BorderSide(color: AppColors.gualda),
        selectedColor: AppColors.rojo,
        secondaryLabelStyle: const TextStyle(color: AppColors.cal),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.gualda,
        thickness: 0.5,
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
