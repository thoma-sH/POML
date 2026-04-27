import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Categorization of every ball on the table. Drives rule logic in the
// game class — type assignment after the break, "hit your own type
// first" foul checking, win/loss on the 8-ball.
enum BallType { cue, solid, eightBall, stripe }

BallType ballTypeForNumber(int number) {
  if (number == 0) return BallType.cue;
  if (number == 8) return BallType.eightBall;
  if (number >= 1 && number <= 7) return BallType.solid;
  if (number >= 9 && number <= 15) return BallType.stripe;
  throw ArgumentError('Invalid pool ball number: $number');
}

// One ball on the pool table. The component owns the Forge2D body and
// renders the ball as a single pre-baked `ui.Image` — every frame is
// just one `canvas.drawImage` call instead of the dozen+ draw ops the
// previous version did. The bake includes shadow, sphere shading,
// number plate (or stripe band), and specular highlight.
//
// Mixes in ContactCallbacks so the cue ball can notify the game class
// about first-contact for "hit your own ball type first" foul detection.
class PoolBall extends BodyComponent with ContactCallbacks {
  PoolBall({
    required this.startPosition,
    required this.color,
    required this.number,
    this.isCueBall = false,
    this.radius = 0.038,
  });

  final Vector2 startPosition;
  final Color color;
  // 0 = cue ball, 1-7 = solids, 8 = eight ball, 9-15 = stripes.
  final int number;
  final bool isCueBall;
  final double radius;

  // Categorization derived from the ball number; used by the rule engine.
  BallType get ballType => ballTypeForNumber(number);

  // Pocket-animation state.
  bool potted = false;
  static const _pottingAnimationDuration = 0.28;
  double _pottingElapsed = 0;
  bool get pottingComplete =>
      potted && _pottingElapsed >= _pottingAnimationDuration;
  double get _pottingProgress =>
      (_pottingElapsed / _pottingAnimationDuration).clamp(0.0, 1.0);

  // Game class registers a callback on the cue ball so it can record
  // what the cue ball touched first during a shot. Other balls leave
  // this null and ignore contact events.
  void Function(Object other)? onCueContact;

  // Globally-shared throttle for collision haptics. Without this every
  // ball-on-ball touch during a break would fire ~30 haptic pulses in
  // half a second and turn the phone into a vibrator.
  static int _lastHapticMs = 0;
  static const _hapticThrottleMs = 80;
  static const _hapticMinSpeed = 2.5;

  @override
  void beginContact(Object other, Contact contact) {
    onCueContact?.call(other);
    _maybeHaptic(other);
  }

  // Fires a tiny haptic on hard ball-on-ball contacts only. Soft taps
  // and the dozens of micro-touches during a settled rack stay silent.
  void _maybeHaptic(Object other) {
    if (other is! PoolBall) return;
    if (!isMounted || !other.isMounted) return;
    if (potted || other.potted) return;
    final relSpeed =
        (body.linearVelocity - other.body.linearVelocity).length;
    if (relSpeed < _hapticMinSpeed) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHapticMs < _hapticThrottleMs) return;
    _lastHapticMs = now;
    HapticFeedback.selectionClick();
  }

  // ── pre-baked sprite ──
  // Resolution we render the bake at. 128 covers ~5x oversampling on a
  // typical phone with the current camera zoom — crisp at any
  // believable in-game zoom level, tiny memory footprint (64KB per ball
  // at 4 bytes per pixel, ~1MB for all 16). Public so the BallTrails
  // overlay can scale ghost copies of the same sprite.
  static const int spritePx = 128;
  ui.Image? _sprite;
  // Read-only handle for the trail overlay — null until onLoad finishes.
  ui.Image? get sprite => _sprite;
  // One Paint instance reused for every drawImage. Only its color
  // alpha changes between frames (during the pocket fade).
  late final Paint _spritePaint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _spritePaint = Paint()..filterQuality = FilterQuality.medium;
    _sprite = _bakeSprite();
  }

  @override
  void onRemove() {
    _sprite?.dispose();
    super.onRemove();
  }

  ui.Image _bakeSprite() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _paintBallToCanvas(canvas, spritePx.toDouble());
    final picture = recorder.endRecording();
    final image = picture.toImageSync(spritePx, spritePx);
    picture.dispose();
    return image;
  }

  // Draws the entire ball into a `spritePx × spritePx` pixel canvas.
  // The ball circle is centered, leaves a few px margin for the shadow.
  void _paintBallToCanvas(Canvas canvas, double size) {
    final cx = size / 2;
    final cy = size / 2;
    final r = size / 2 - 6; // visual margin

    // ── Drop shadow (inside the sprite footprint) ──
    canvas.drawCircle(
      Offset(cx + 2.5, cy + 4.5),
      r * 0.96,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    // ── Sphere-shaded fill ──
    final light = Color.lerp(color, Colors.white, 0.28)!;
    final dark = Color.lerp(color, Colors.black, 0.42)!;
    final fillRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.18, -0.28),
          colors: [light, color, dark],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(fillRect),
    );

    // ── Stripe band (only on stripes 9-15) ──
    if (!isCueBall && number >= 9 && number <= 15) {
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
      );
      // White band with subtle vertical shading so it reads as a band
      // wrapping a sphere, not a flat stripe.
      final bandRect = Rect.fromCenter(
        center: Offset(cx, cy),
        width: r * 2,
        height: r * 0.9,
      );
      canvas.drawRect(
        bandRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.92),
              Colors.white,
              Colors.white.withValues(alpha: 0.92),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bandRect),
      );
      canvas.restore();
    }

    // ── Number plate (white circle with the digit) ──
    if (!isCueBall && number > 0) {
      final plateRadius = r * 0.42;
      // Slight inner shadow on the plate for "embedded" feel.
      canvas.drawCircle(
        Offset(cx + 0.5, cy + 1),
        plateRadius * 1.04,
        Paint()..color = Colors.black.withValues(alpha: 0.18),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        plateRadius,
        Paint()..color = Colors.white,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: '$number',
          style: TextStyle(
            color: const Color(0xFF14171A),
            fontSize: r * 0.62,
            fontWeight: FontWeight.w800,
            height: 1.0,
            letterSpacing: -0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }

    // ── Cue ball red dot for rotation visibility ──
    if (isCueBall) {
      canvas.drawCircle(
        Offset(cx + r * 0.45, cy),
        r * 0.13,
        Paint()..color = const Color(0xFFE63946),
      );
    }

    // ── Specular highlight (lit from upper-left) ──
    final highlightCenter = Offset(cx - r * 0.34, cy - r * 0.38);
    canvas.drawCircle(
      highlightCenter,
      r * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.78),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(
          Rect.fromCircle(center: highlightCenter, radius: r * 0.55),
        ),
    );

    // ── Bottom-rim darkening (subtle) — adds dimension by darkening
    // the underside that's facing away from the light source.
    canvas.drawCircle(
      Offset(cx + r * 0.12, cy + r * 0.42),
      r * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.black.withValues(alpha: 0.18),
            Colors.black.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: Offset(cx + r * 0.12, cy + r * 0.42),
            radius: r * 0.55,
          ),
        ),
    );
  }

  @override
  Body createBody() {
    final shape = CircleShape()..radius = radius;
    final fixtureDef = FixtureDef(
      shape,
      density: 1.0,
      // Higher ball-on-ball friction transfers angular momentum on
      // collisions, which makes other balls spin a bit when hit and
      // sells the rolling motion visually.
      friction: 0.10,
      restitution: 0.88,
      userData: this,
    );
    final bodyDef = BodyDef(
      position: startPosition.clone(),
      type: BodyType.dynamic,
      // Damping tuned together with the direct-velocity shot model in
      // EightBallGame._shoot. With a max shot velocity of ~12 m/s, a
      // damping of 1.6 brings a hard shot to rest in roughly 4 seconds —
      // close to a real pool table on cloth. Angular damping is matched
      // so the visible spin fades around the same time as motion.
      linearDamping: 1.6,
      angularDamping: 1.4,
      bullet: isCueBall,
      userData: this,
    );
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    final sprite = _sprite;
    if (sprite == null) return;
    if (pottingComplete) return;

    // Apply pocket-fade alpha by mutating the cached paint's color in
    // place — single field write, no allocation.
    final fade = potted ? (1.0 - _pottingProgress).clamp(0.0, 1.0) : 1.0;
    _spritePaint.color = Colors.white.withValues(alpha: fade);

    // Sprite was baked at spritePx; scale it down to the ball's
    // actual world diameter (2 * radius). During potting the ball
    // shrinks AND drifts a little along the local-Y axis so it reads
    // as "falling into the pocket" rather than just deflating.
    final scale = (2 * radius) / spritePx;
    final pottedScale = potted ? (1.0 - _pottingProgress * 0.7) : 1.0;
    // Cubic ease-in for the drop — slow start, accelerating fall, like
    // a ball that just lost its support against gravity.
    final dropEase = potted ? (_pottingProgress * _pottingProgress) : 0.0;
    final drop = radius * 0.45 * dropEase;

    canvas.save();
    canvas.translate(0, drop);
    canvas.scale(scale * pottedScale);
    canvas.drawImage(
      sprite,
      const Offset(-spritePx / 2, -spritePx / 2),
      _spritePaint,
    );
    canvas.restore();
  }

  // Re-spots the ball at a known position with zero velocity. Used for
  // cue-ball respawn after a scratch.
  void respawnAt(Vector2 pos) {
    body.setTransform(pos, 0);
    body.linearVelocity = Vector2.zero();
    body.angularVelocity = 0;
    potted = false;
    _pottingElapsed = 0;
    if (body.fixtures.isNotEmpty) {
      body.fixtures.first.setSensor(false);
    }
  }

  // Called by the game the moment the ball drops into a pocket. Snaps
  // the ball to the pocket center, zeroes its motion, and switches the
  // fixture to a sensor so other balls can pass through it during the
  // shrink-and-fade animation that follows.
  void markPotted(Vector2 pocketCenter) {
    if (potted) return;
    potted = true;
    _pottingElapsed = 0;
    body.setTransform(pocketCenter, 0);
    body.linearVelocity = Vector2.zero();
    body.angularVelocity = 0;
    if (body.fixtures.isNotEmpty) {
      body.fixtures.first.setSensor(true);
    }
  }

  void tickPottingAnimation(double dt) {
    if (!potted) return;
    _pottingElapsed += dt;
  }

  bool get isResting {
    if (potted) return true;
    if (!isMounted) return true;
    final v = body.linearVelocity.length;
    return v < 0.02;
  }
}

// Vertical-orientation rack: apex ball faces the cue ball (which sits
// below it on the table), and the back rows fan out upward. Used by
// the portrait-mode camera so the whole table fits on a phone screen.
List<Vector2> rackPositions(Vector2 apex, double spacing) {
  final positions = <Vector2>[];
  final rowGap = spacing * math.cos(math.pi / 6); // distance between rows
  final ballGap = spacing; // distance between balls within a row
  for (var row = 0; row < 5; row++) {
    final ballsInRow = row + 1;
    final rowY = apex.y - row * rowGap; // rows extend up (away from cue)
    final xStart = apex.x - ((ballsInRow - 1) * ballGap) / 2;
    for (var i = 0; i < ballsInRow; i++) {
      positions.add(Vector2(xStart + i * ballGap, rowY));
    }
  }
  return positions;
}
