import 'dart:collection';
import 'dart:ui' as ui;

import 'package:first_flutter_app/features/game/presentation/games/eight_ball/components/pool_ball.dart';
import 'package:flame/components.dart' hide Vector2;
import 'package:flutter/material.dart';

// Lightweight "motion blur" overlay for fast-moving balls. Each frame
// it samples the position of every still-mounted ball whose speed is
// above a threshold, stores a ring buffer of recent positions, and
// renders fading ghost copies of the cached ball sprite at each one.
//
// Lives in the Forge2D world at a priority that puts it under the
// balls themselves so the live ball draws on top of its own trail.
class BallTrails extends Component {
  BallTrails(this._balls);

  // Reference to the game's authoritative ball list — we don't own
  // the balls, just observe them.
  final List<PoolBall> _balls;

  // How many past samples to draw per ball. Higher = longer trail
  // but more draw calls per frame.
  static const _trailLength = 6;

  // Below this speed we don't bother sampling — keeps the trail
  // calm during aim and after the table has settled.
  static const _minSpeedForTrail = 1.8;

  // Draw under the balls; balls' default priority is 0.
  @override
  int get priority => -5;

  // Per-ball ring buffers. Using Queue<Offset> for cheap O(1)
  // add-front / remove-back. The Offset doubles are world coords.
  final Map<PoolBall, Queue<Offset>> _history = {};

  // Reused per-frame Paint object — only the color alpha changes
  // between draws, no allocations in the hot path.
  final Paint _ghostPaint = Paint()..filterQuality = FilterQuality.low;

  @override
  void update(double dt) {
    super.update(dt);
    for (final ball in _balls) {
      if (!ball.isMounted || ball.potted) {
        _history.remove(ball);
        continue;
      }
      final speed = ball.body.linearVelocity.length;
      final history = _history.putIfAbsent(ball, () => Queue<Offset>());
      if (speed < _minSpeedForTrail) {
        if (history.isNotEmpty) history.clear();
        continue;
      }
      final pos = ball.body.position;
      history.addFirst(Offset(pos.x, pos.y));
      while (history.length > _trailLength) {
        history.removeLast();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    for (final entry in _history.entries) {
      final ball = entry.key;
      final history = entry.value;
      final sprite = ball.sprite;
      if (sprite == null || history.isEmpty) continue;
      _drawTrail(canvas, ball, sprite, history);
    }
  }

  void _drawTrail(
    Canvas canvas,
    PoolBall ball,
    ui.Image sprite,
    Queue<Offset> history,
  ) {
    final spriteScale = (2 * ball.radius) / PoolBall.spritePx;
    final n = history.length;
    var i = 0;
    for (final pos in history) {
      // Skip the most recent sample — that's where the live ball
      // already draws itself; we'd just be doubling it.
      if (i == 0) {
        i++;
        continue;
      }
      // Older samples fade quadratically and shrink slightly so the
      // trail tapers naturally toward zero.
      final t = i / n;
      final alpha = (1 - t) * (1 - t) * 0.45;
      final shrink = 1 - t * 0.3;
      _ghostPaint.color = Colors.white.withValues(alpha: alpha);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.scale(spriteScale * shrink);
      canvas.drawImage(
        sprite,
        const Offset(-PoolBall.spritePx / 2, -PoolBall.spritePx / 2),
        _ghostPaint,
      );
      canvas.restore();
      i++;
    }
  }
}
