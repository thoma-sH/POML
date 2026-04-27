import 'dart:ui' as ui;

import 'package:flame/components.dart' hide Vector2;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

// Visual-only table component. Bakes the entire table — wood rail with
// rounded inner corners, felt, vignette, cushion strips, pockets, and
// diamond markers — into a single `ui.Image` during onLoad. Each
// frame after that is a single `canvas.drawImage` call instead of the
// 30+ draw operations the previous implementation performed.
//
// Physics bodies (cushion walls) are NOT children of this component —
// flame_forge2d's BodyComponent.world cast assumes the parent IS the
// Forge2DWorld, so all BodyComponents must be added directly there.
// The game class owns those instead and uses the pocketCenters list
// below for ball-in-pocket testing.
class PoolTable extends PositionComponent {
  PoolTable({
    required Vector2 tableSize,
    this.pocketRadius = 0.095,
    this.cushionThickness = 0.05,
  }) : _tableSize = tableSize.clone();

  final Vector2 _tableSize;
  final double pocketRadius;
  final double cushionThickness;

  // Render under everything else.
  @override
  int get priority => -10;

  // Six pocket centers in world coords, used by the game class to detect
  // when a ball drops in.
  late final List<Vector2> pocketCenters = _computePocketCenters();

  // Pre-baked sprite of the entire table (rails + felt + pockets +
  // diamonds). Built once in onLoad, blitted every frame thereafter.
  ui.Image? _baked;
  late final Paint _blitPaint;

  // Resolution we render the bake at. Higher = sharper at zoom but
  // more GPU memory. ~800×1600 covers a phone at 3× DPR with the
  // current camera zoom and stays well under the 2k×2k tile limit.
  static const int _bakedPxWidth = 800;
  static const int _bakedPxHeight = 1600;

  // Returns the cushion segments (start/end pairs) that the game class
  // turns into static EdgeShape bodies and adds directly to the world.
  List<({Vector2 from, Vector2 to})> cushionSegments() {
    final hw = _tableSize.x / 2;
    final hh = _tableSize.y / 2;
    final gap = pocketRadius * 0.95;
    return [
      // top rail (split for the side pocket)
      (from: Vector2(-hw + pocketRadius, -hh), to: Vector2(-gap, -hh)),
      (from: Vector2(gap, -hh), to: Vector2(hw - pocketRadius, -hh)),
      // bottom rail
      (from: Vector2(-hw + pocketRadius, hh), to: Vector2(-gap, hh)),
      (from: Vector2(gap, hh), to: Vector2(hw - pocketRadius, hh)),
      // left rail
      (from: Vector2(-hw, -hh + pocketRadius), to: Vector2(-hw, hh - pocketRadius)),
      // right rail
      (from: Vector2(hw, -hh + pocketRadius), to: Vector2(hw, hh - pocketRadius)),
    ];
  }

  List<Vector2> _computePocketCenters() {
    final hw = _tableSize.x / 2;
    final hh = _tableSize.y / 2;
    return [
      Vector2(-hw + 0.02, -hh + 0.02),
      Vector2(hw - 0.02, -hh + 0.02),
      Vector2(-hw + 0.02, hh - 0.02),
      Vector2(hw - 0.02, hh - 0.02),
      Vector2(0, -hh + 0.012),
      Vector2(0, hh - 0.012),
    ];
  }

  @override
  Future<void> onLoad() async {
    _blitPaint = Paint()..filterQuality = FilterQuality.medium;
    _baked = _bakeTableImage();
  }

  @override
  void onRemove() {
    _baked?.dispose();
    super.onRemove();
  }

  // The big one: paints everything to a PictureRecorder canvas in pixel
  // coords, then snaps the picture into a GPU-resident ui.Image.
  ui.Image _bakeTableImage() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _paintTableInPixels(canvas, _bakedPxWidth.toDouble(), _bakedPxHeight.toDouble());
    final picture = recorder.endRecording();
    final image = picture.toImageSync(_bakedPxWidth, _bakedPxHeight);
    picture.dispose();
    return image;
  }

  // All draws below operate in baked-pixel space (0..w, 0..h). The
  // outer frame is the full image; the felt occupies a rectangle inset
  // by cushionThicknessPx on every side.
  void _paintTableInPixels(Canvas canvas, double w, double h) {
    // pixels-per-meter for converting world dims into baked-pixel dims.
    // We bake the IMAGE to cover the full table footprint including
    // the wood rails, so the baked area is (tableSize + 2*cushion).
    // Aspect mismatch between bake and world is absorbed by the
    // render-time scale, so a single px scalar is sufficient here.
    final worldW = _tableSize.x + cushionThickness * 2;
    final px = w / worldW;
    final cushionPx = cushionThickness * px;

    // ── Outer wood rail with rounded corners ──
    final railRect = Rect.fromLTWH(0, 0, w, h);
    final railRadius = cushionPx * 1.4;
    final railShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        Color(0xFF4A2E1E), // walnut highlight
        Color(0xFF2A1810), // shadow
      ],
    ).createShader(railRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(railRect, Radius.circular(railRadius)),
      Paint()..shader = railShader,
    );

    // Subtle horizontal wood-grain striations to break up the flat rail.
    final grainPaint = Paint()
      ..color = const Color(0xFF1F100A).withValues(alpha: 0.32)
      ..strokeWidth = 1;
    for (var y = 0.0; y < h; y += 9) {
      canvas.drawLine(Offset(0, y), Offset(w, y), grainPaint);
    }

    // ── Felt area ──
    final feltRect = Rect.fromLTWH(
      cushionPx,
      cushionPx,
      w - cushionPx * 2,
      h - cushionPx * 2,
    );
    canvas.drawRect(
      feltRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [Color(0xFF2C8C50), Color(0xFF1F6B3B)],
        ).createShader(feltRect),
    );

    // Felt vignette — slightly darker at the edges to fake table depth.
    canvas.drawRect(
      feltRect,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0x00000000),
            Color(0x40000000),
          ],
          stops: const [0.55, 1.0],
        ).createShader(feltRect),
    );

    // ── Cushion strips (lighter green band along each rail) ──
    final cushionStripPaint = Paint()
      ..color = const Color(0xFF2A8C50)
      ..strokeWidth = cushionPx * 0.45
      ..strokeCap = StrokeCap.round;
    final pocketPx = pocketRadius * px;
    final gapPx = pocketPx * 0.95;
    final cushionInset = cushionPx + cushionStripPaint.strokeWidth * 0.5;

    // top rail (split around side pocket if any — top is short rail)
    canvas.drawLine(
      Offset(cushionPx + pocketPx, cushionInset),
      Offset(w / 2 - gapPx, cushionInset),
      cushionStripPaint,
    );
    canvas.drawLine(
      Offset(w / 2 + gapPx, cushionInset),
      Offset(w - cushionPx - pocketPx, cushionInset),
      cushionStripPaint,
    );
    // bottom rail
    canvas.drawLine(
      Offset(cushionPx + pocketPx, h - cushionInset),
      Offset(w / 2 - gapPx, h - cushionInset),
      cushionStripPaint,
    );
    canvas.drawLine(
      Offset(w / 2 + gapPx, h - cushionInset),
      Offset(w - cushionPx - pocketPx, h - cushionInset),
      cushionStripPaint,
    );
    // left rail (split around side pocket at h/2)
    canvas.drawLine(
      Offset(cushionInset, cushionPx + pocketPx),
      Offset(cushionInset, h / 2 - gapPx),
      cushionStripPaint,
    );
    canvas.drawLine(
      Offset(cushionInset, h / 2 + gapPx),
      Offset(cushionInset, h - cushionPx - pocketPx),
      cushionStripPaint,
    );
    // right rail
    canvas.drawLine(
      Offset(w - cushionInset, cushionPx + pocketPx),
      Offset(w - cushionInset, h / 2 - gapPx),
      cushionStripPaint,
    );
    canvas.drawLine(
      Offset(w - cushionInset, h / 2 + gapPx),
      Offset(w - cushionInset, h - cushionPx - pocketPx),
      cushionStripPaint,
    );

    // ── Diamond markers on the rails ──
    final diamondPaint = Paint()..color = const Color(0xFFEFE3D0);
    final diamondSize = cushionPx * 0.22;
    // Long (vertical) rails: 3 diamonds in the upper half between top
    // corner and side pocket, plus 3 in the lower half. 6 per rail.
    final longRailY = [
      cushionPx + (h / 2 - cushionPx) * 0.25,
      cushionPx + (h / 2 - cushionPx) * 0.5,
      cushionPx + (h / 2 - cushionPx) * 0.75,
      h / 2 + (h / 2 - cushionPx) * 0.25,
      h / 2 + (h / 2 - cushionPx) * 0.5,
      h / 2 + (h / 2 - cushionPx) * 0.75,
    ];
    final leftRailX = cushionPx * 0.5;
    final rightRailX = w - cushionPx * 0.5;
    for (final y in longRailY) {
      _drawDiamond(canvas, Offset(leftRailX, y), diamondSize, diamondPaint);
      _drawDiamond(canvas, Offset(rightRailX, y), diamondSize, diamondPaint);
    }
    // Short (horizontal) rails: 3 diamonds evenly spaced across.
    final shortRailX = [w * 0.25, w * 0.5, w * 0.75];
    final topRailY = cushionPx * 0.5;
    final bottomRailY = h - cushionPx * 0.5;
    for (final x in shortRailX) {
      _drawDiamond(canvas, Offset(x, topRailY), diamondSize, diamondPaint);
      _drawDiamond(canvas, Offset(x, bottomRailY), diamondSize, diamondPaint);
    }

    // ── Pockets — black circles painted last so they punch holes
    // through the rail/cushion overlay. Slight darker rim outside the
    // hole sells the depth of a real pocket cup.
    final pocketPaint = Paint()..color = Colors.black;
    final pocketRimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = pocketPx * 0.18;
    for (final pc in pocketCenters) {
      final cx = pc.x * px + w / 2;
      final cy = pc.y * px + h / 2;
      canvas.drawCircle(Offset(cx, cy), pocketPx * 1.18, pocketRimPaint);
      canvas.drawCircle(Offset(cx, cy), pocketPx, pocketPaint);
    }

    // ── Headstring (faint reference line in the cue ball area) ──
    canvas.drawLine(
      Offset(cushionPx, h * 0.625),
      Offset(w - cushionPx, h * 0.625),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..strokeWidth = 1.2,
    );
  }

  void _drawDiamond(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size * 0.7, center.dy)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size * 0.7, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  // Render in world coords: scale the baked pixel image down to the
  // table's actual world dimensions and translate so its center sits
  // at the world origin.
  @override
  void render(Canvas canvas) {
    final img = _baked;
    if (img == null) return;
    final worldW = _tableSize.x + cushionThickness * 2;
    final worldH = _tableSize.y + cushionThickness * 2;
    final scaleX = worldW / _bakedPxWidth;
    final scaleY = worldH / _bakedPxHeight;

    canvas.save();
    canvas.scale(scaleX, scaleY);
    canvas.drawImage(
      img,
      Offset(-_bakedPxWidth / 2, -_bakedPxHeight / 2),
      _blitPaint,
    );
    canvas.restore();
  }
}

// Static cushion body. EdgeShape collider with a tuned restitution.
// Real pool cushions are slightly angle-dependent (more bounce on
// head-on hits, less on glancing) but Forge2D 0.13 doesn't expose a
// per-contact restitution setter, so we use a single value tuned to
// a believable middle ground.
class CushionBody extends BodyComponent {
  CushionBody({required this.from, required this.to});

  final Vector2 from;
  final Vector2 to;

  @override
  bool get renderBody => false;

  @override
  Body createBody() {
    final shape = EdgeShape()..set(from, to);
    final fixtureDef = FixtureDef(
      shape,
      friction: 0.07,
      // Tuned by feel against real pool footage at 220 px/m camera zoom.
      // Below ~0.6 the cushions feel mushy; above ~0.7 the balls bounce
      // around like a Pong screensaver.
      restitution: 0.66,
    );
    final bodyDef = BodyDef(type: BodyType.static);
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}
