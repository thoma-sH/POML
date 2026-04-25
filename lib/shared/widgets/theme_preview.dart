import 'dart:math' as math;

import 'package:first_flutter_app/shared/theme/lacuna_theme.dart';
import 'package:flutter/material.dart';

class ThemePreview extends StatelessWidget {
  const ThemePreview({required this.theme, super.key});

  final LacunaTheme theme;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _ThemePreviewPainter(theme: theme),
        size: Size.infinite,
      ),
    );
  }
}

class _ThemePreviewPainter extends CustomPainter {
  _ThemePreviewPainter({required this.theme});

  final LacunaTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintSurfaceSample(canvas, size);
    _paintAccentMark(canvas, size);
  }

  void _paintBackground(Canvas canvas, Size size) {
    final p = theme.palette;
    final rect = Offset.zero & size;

    switch (theme.backgroundMode) {
      case BackgroundMode.flat:
        canvas.drawRect(rect, Paint()..color = p.bgBase);

      case BackgroundMode.gradient:
        final gradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: theme.bgGradient,
        ).createShader(rect);
        canvas.drawRect(rect, Paint()..shader = gradient);

      case BackgroundMode.orbs:
        canvas.drawRect(rect, Paint()..color = p.bgDeep);
        _paintOrb(
          canvas,
          size,
          center: Offset(size.width * 0.7, size.height * 0.3),
          radius: size.shortestSide * 0.55,
          color: p.accent.withValues(alpha: 0.4),
        );
        _paintOrb(
          canvas,
          size,
          center: Offset(size.width * 0.2, size.height * 0.75),
          radius: size.shortestSide * 0.5,
          color: p.accentDeep.withValues(alpha: 0.32),
        );

      case BackgroundMode.aurora:
        final gradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: theme.bgGradient,
        ).createShader(rect);
        canvas.drawRect(rect, Paint()..shader = gradient);
        _paintAuroraRibbon(
          canvas,
          size,
          center: Offset(size.width * 0.35, size.height * 0.3),
          color: p.accent.withValues(alpha: 0.28),
          angle: -0.25,
        );
        _paintAuroraRibbon(
          canvas,
          size,
          center: Offset(size.width * 0.65, size.height * 0.65),
          color: p.accentDeep.withValues(alpha: 0.22),
          angle: 0.15,
        );

      case BackgroundMode.noise:
        final gradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: theme.bgGradient,
        ).createShader(rect);
        canvas.drawRect(rect, Paint()..shader = gradient);
        _paintNoise(canvas, size);
    }
  }

  void _paintOrb(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final shader = RadialGradient(
      colors: [color, color.withValues(alpha: 0), Colors.transparent],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, Paint()..shader = shader);
  }

  void _paintAuroraRibbon(
    Canvas canvas,
    Size size, {
    required Offset center,
    required Color color,
    required double angle,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.width * 1.4,
      height: size.height * 0.5,
    );
    final shader = RadialGradient(
      colors: [color, color.withValues(alpha: 0), Colors.transparent],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(rect);
    canvas.drawOval(rect, Paint()..shader = shader);
    canvas.restore();
  }

  void _paintNoise(Canvas canvas, Size size) {
    final rng = math.Random(13);
    final paint = Paint()..style = PaintingStyle.fill;
    final count = (size.width * size.height * 0.25).round();
    for (var i = 0; i < count; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      final shade = rng.nextDouble();
      paint.color = (shade > 0.5 ? Colors.white : Colors.black).withValues(
        alpha: 0.06 * (0.5 + rng.nextDouble() * 0.5),
      );
      canvas.drawCircle(Offset(dx, dy), 0.45, paint);
    }
  }

  void _paintSurfaceSample(Canvas canvas, Size size) {
    final p = theme.palette;
    final margin = size.width * 0.16;
    final rect = Rect.fromLTWH(
      margin,
      size.height * 0.55,
      size.width - margin * 2,
      size.height * 0.28,
    );
    final radius = Radius.circular(8 * theme.radiusScale + 4);
    final rrect = RRect.fromRectAndRadius(rect, radius);

    switch (theme.surfaceStyle) {
      case SurfaceStyle.solid:
        canvas.drawRRect(rrect, Paint()..color = p.surface1);
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = p.borderSubtle
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );

      case SurfaceStyle.paper:
        canvas.drawRRect(
          rrect.shift(const Offset(0, 1)),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.08 * theme.depthShadow)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawRRect(rrect, Paint()..color = p.surface1);

      case SurfaceStyle.frosted:
        final tint = p.brightness == Brightness.light
            ? Colors.white.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.1);
        canvas.drawRRect(rrect, Paint()..color = tint);
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.6,
        );

      case SurfaceStyle.liquidGlass:
        final isLight = p.brightness == Brightness.light;
        final tintTop = (isLight ? Colors.white : Colors.white)
            .withValues(alpha: isLight ? 0.55 : 0.16);
        final tintBottom = (isLight ? Colors.white : Colors.white)
            .withValues(alpha: isLight ? 0.3 : 0.06);
        final shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tintTop, tintBottom],
        ).createShader(rect);
        canvas.drawRRect(rrect, Paint()..shader = shader);
        // specular top edge
        final spec = LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: theme.specularOpacity * 2.5),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromLTWH(rect.left, rect.top, rect.width, 1),
        );
        canvas.drawRect(
          Rect.fromLTWH(rect.left, rect.top, rect.width, 1),
          Paint()..shader = spec,
        );
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.22)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.6,
        );
    }
  }

  void _paintAccentMark(Canvas canvas, Size size) {
    final p = theme.palette;
    final cx = size.width * 0.22;
    final cy = size.height * 0.28;
    final r = size.shortestSide * 0.09;
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = p.accent,
    );
  }

  @override
  bool shouldRepaint(_ThemePreviewPainter old) =>
      old.theme.variant != theme.variant;
}
