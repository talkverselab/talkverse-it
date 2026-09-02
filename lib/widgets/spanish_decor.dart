import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Azulejo — 타일 배지. 짧은 라벨(1~4자) 표시. zh 의 SealStamp 대응.
class TileBadge extends StatelessWidget {
  final String text;
  final double size;
  final Color? color;

  const TileBadge({
    super.key,
    required this.text,
    this.size = 56,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.rojo;
    final len = text.runes.length;
    final fontSize = len <= 1 ? size * 0.55 : (len <= 2 ? size * 0.4 : size * 0.26);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(size * 0.18),
        border: Border.all(color: AppColors.gualda, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.cal,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// 상하 금색 띠가 있는 패널.
class BandPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color background;

  const BandPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.background = AppColors.cal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.gualda.withValues(alpha: 0.6), width: 3),
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// 국기 삼색 띠 구분선 (rojo·gualda·rojo).
class BandDivider extends StatelessWidget {
  final double height;
  const BandDivider({super.key, this.height = 6});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: height / 4, color: AppColors.rojo),
        Container(height: height / 2, color: AppColors.gualda),
        Container(height: height / 4, color: AppColors.rojo),
      ],
    );
  }
}

/// 아줄레주 타일 패턴 배경 (Stack Positioned.fill 권장).
class AzulejoPattern extends StatelessWidget {
  final double opacity;
  final double cell;
  const AzulejoPattern({super.key, this.opacity = 0.06, this.cell = 48});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _AzulejoPainter(opacity: opacity, cell: cell),
      ),
    );
  }
}

class _AzulejoPainter extends CustomPainter {
  final double opacity;
  final double cell;
  _AzulejoPainter({required this.opacity, required this.cell});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.mar.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double y = 0; y < size.height + cell; y += cell) {
      for (double x = 0; x < size.width + cell; x += cell) {
        final cx = x + cell / 2;
        final cy = y + cell / 2;
        final r = cell * 0.32;
        final path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r, cy)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawCircle(Offset(cx, cy), r * 0.35, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AzulejoPainter old) =>
      old.opacity != opacity || old.cell != cell;
}

/// 연속 학습 배지.
class StreakChip extends StatelessWidget {
  final int days;
  const StreakChip({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.rojo,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gualda, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$days',
            style: const TextStyle(
              color: AppColors.cal,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// 태양 문양 (Sol) — 작은 장식.
class SolMark extends StatelessWidget {
  final double size;
  final Color? color;
  const SolMark({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _SolPainter(color ?? AppColors.gualda),
    );
  }
}

class _SolPainter extends CustomPainter {
  final Color color;
  _SolPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.22;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(c, r, paint);
    final ray = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final p1 = c + Offset(math.cos(a), math.sin(a)) * (r * 1.5);
      final p2 = c + Offset(math.cos(a), math.sin(a)) * (size.width / 2 - 1);
      canvas.drawLine(p1, p2, ray);
    }
  }

  @override
  bool shouldRepaint(covariant _SolPainter old) => old.color != color;
}
