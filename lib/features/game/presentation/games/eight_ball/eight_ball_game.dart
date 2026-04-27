import 'dart:math' as math;

import 'package:first_flutter_app/features/game/presentation/games/eight_ball/components/ball_trails.dart';
import 'package:first_flutter_app/features/game/presentation/games/eight_ball/components/pool_ball.dart';
import 'package:first_flutter_app/features/game/presentation/games/eight_ball/components/pool_table.dart';
import 'package:flame/components.dart' hide Vector2;
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Whose shot it is. Hot-seat — both players use the same device, the
// app just shows whose turn it is and rotates after each completed shot.
enum PoolPlayer { a, b }

// What the game is currently waiting for. Used to gate touch input
// between aiming a shot and placing the cue ball after a foul.
enum PoolInputMode { aim, ballInHand }

// The Forge2D game itself. Owns the table, balls, cue aim, and turn
// rotation. Flame's `update` runs the physics loop; we hook in to (a)
// detect when all balls have come to rest so the turn can advance,
// and (b) check pocket sensors against ball positions to pot balls.
class EightBallGame extends Forge2DGame with DragCallbacks, TapCallbacks {
  EightBallGame({
    required this.onTurnChanged,
    required this.onScoreChanged,
    required this.onGameOver,
    this.onTypeAssigned,
    this.onInputModeChanged,
  }) : super(gravity: Vector2.zero());

  // Callbacks back into the Flutter widget so the surrounding HUD can
  // re-render. Keeping the game pure-Flame and exposing observers means
  // the widget can stay a regular Flutter widget without touching
  // Forge2D state.
  final ValueChanged<PoolPlayer> onTurnChanged;
  final void Function(int scoreA, int scoreB) onScoreChanged;
  final void Function(PoolPlayer winner) onGameOver;
  // Fires once after the open break when stripes/solids get assigned to
  // each player. The HUD uses it to re-label the player slots.
  final void Function(PoolPlayer player, BallType type)? onTypeAssigned;
  // Fires whenever the game flips between "aim a shot" and "place the
  // cue ball after a foul," so the HUD can show the right prompt.
  final ValueChanged<PoolInputMode>? onInputModeChanged;

  // Portrait-oriented table: short side is X, long side is Y. Fits a
  // phone screen far better than the landscape pool-hall layout.
  static const tableWidth = 1.2;
  static const tableHeight = 2.4;

  // Cue ball respawns at the head spot — bottom of the table in the
  // vertical layout, opposite where the rack sits.
  static const cueSpawnY = tableHeight / 4;
  static const rackApexY = -tableHeight / 4;

  late final PoolTable _table;
  late final PoolBall _cueBall;
  final List<PoolBall> _objectBalls = [];

  // Per-player tally of balls pocketed. We don't yet enforce stripes vs
  // solids — first to seven wins for now. Eight-ball-specific rules
  // come in a future polish pass.
  int scoreA = 0;
  int scoreB = 0;

  PoolPlayer currentTurn = PoolPlayer.a;
  bool gameOver = false;

  // Stripes/solids assignment per player. Both null means the table
  // is "open" — types haven't been claimed yet (the standard state
  // immediately after the break).
  BallType? playerAType;
  BallType? playerBType;
  bool get isTableOpen => playerAType == null;

  // Whose turn just fouled — that player's opponent gets to place the
  // cue ball anywhere before their next shot.
  PoolInputMode inputMode = PoolInputMode.aim;

  // Set true the moment the cue ball is struck. Flips back to false
  // once every ball is at rest, which is the trigger for `_endShot`.
  bool _shotInFlight = false;

  // Per-shot tracking — reset at the start of every shot, read in
  // `_endShot` to decide what happened.
  PoolBall? _firstBallContacted;

  // Aim state — tracked in canvas pixel space (Offset) so we don't have
  // to play games with the dual-precision Vector2 types between flame
  // and forge2d. We construct a forge2d Vector2 only at impulse time.
  Offset? _aimDragStart;
  Offset? _aimDragCurrent;

  // Shot tuning. Velocity is applied directly (not via impulse) so the
  // shot magnitude is independent of ball mass and Box2D's internal
  // velocity clamps. 12 m/s is a believable "hard break" speed; lighter
  // shots scale down linearly with how far the player drags.
  static const _maxShotVelocity = 12.0;
  static const _maxPullPixels = 250.0;
  static const _minPullPixels = 8.0;

  // Single source of truth for "drag distance → shot power 0..1" so the
  // aim guide visuals always match the shot the player will actually
  // get on release.
  static double powerRatioForPull(double pullPixels) {
    if (pullPixels <= _minPullPixels) return 0.0;
    return ((pullPixels - _minPullPixels) /
            (_maxPullPixels - _minPullPixels))
        .clamp(0.0, 1.0);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Center the camera on the world origin and pick a zoom that fits
    // the table comfortably on a typical phone screen with a margin
    // for the rails. flame_forge2d's default camera doesn't center
    // automatically — we have to do it ourselves.
    // Vertical layout fits the phone screen, so we can zoom in
    // generously — 220 px/m fills nearly the whole game widget with
    // the table while leaving room for the rails.
    camera.viewfinder
      ..anchor = Anchor.center
      ..position = Vector2.zero()
      ..zoom = 220;

    _table = PoolTable(tableSize: Vector2(tableWidth, tableHeight));
    world.add(_table);

    // Cushions go directly in the world — flame_forge2d's
    // BodyComponent assumes its parent IS the Forge2DWorld, so
    // nesting them inside the table component would break the
    // physics body creation.
    for (final seg in _table.cushionSegments()) {
      world.add(CushionBody(from: seg.from, to: seg.to));
    }

    _placeBalls();

    // Motion-blur overlay underneath the balls. Reads the live ball
    // list and draws fading ghost copies behind anything moving fast.
    world.add(BallTrails([_cueBall, ..._objectBalls]));

    // High-priority overlay that draws the aim line + cue stick while
    // the player is dragging. Lives in the world so it renders in the
    // same coord space as the balls.
    world.add(AimGuide(this));
  }

  // ─── public read-only state for the aim overlay ─────────
  Offset? get aimDragStart => _aimDragStart;
  Offset? get aimDragCurrent => _aimDragCurrent;
  PoolBall get cueBall => _cueBall;

  void _placeBalls() {
    // Cue ball spawns at the head spot — bottom of the vertical table.
    _cueBall = PoolBall(
      startPosition: Vector2(0, cueSpawnY),
      color: Colors.white,
      number: 0,
      isCueBall: true,
    );
    // Route the cue ball's contact events back to the rule engine so
    // we know what it touched first this shot. Other balls don't get
    // a callback — we only care about the cue's first contact.
    _cueBall.onCueContact = _handleCueContact;
    world.add(_cueBall);

    // Ball palette — solids on 1-7, eight ball, then stripes for 9-15.
    const ballColors = <int, Color>{
      1: Color(0xFFE8B61F),
      2: Color(0xFF1E5FB0),
      3: Color(0xFFD4391E),
      4: Color(0xFF6E3DA8),
      5: Color(0xFFE9853B),
      6: Color(0xFF1F8345),
      7: Color(0xFF7A2632),
      8: Color(0xFF111111),
      9: Color(0xFFE8B61F),
      10: Color(0xFF1E5FB0),
      11: Color(0xFFD4391E),
      12: Color(0xFF6E3DA8),
      13: Color(0xFFE9853B),
      14: Color(0xFF1F8345),
      15: Color(0xFF7A2632),
    };

    // Spacing tuned to the bumped 0.038-radius balls so neighbors don't
    // overlap when the rack settles. Apex sits on the foot spot at the
    // top of the vertical table; rows fan upward away from the cue.
    final spacing = 0.038 * 2 + 0.001;
    final positions = rackPositions(
      Vector2(0, rackApexY),
      spacing,
    );

    // Standard 8-ball rack: 1 at apex, 8 in the middle of the third row.
    const rackOrder = [
      1,
      11, 9,
      3, 8, 14,
      6, 10, 13, 4,
      7, 5, 15, 12, 2,
    ];

    for (var i = 0; i < positions.length && i < rackOrder.length; i++) {
      final n = rackOrder[i];
      final ball = PoolBall(
        startPosition: positions[i],
        color: ballColors[n]!,
        number: n,
      );
      _objectBalls.add(ball);
      world.add(ball);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameOver) return;
    _checkPockets();
    _tickPottingAnimations(dt);
    if (_shotInFlight) {
      // All balls at rest? Time to swap turns.
      final allResting = _cueBall.isResting &&
          _objectBalls.every((b) => b.isResting);
      if (allResting) {
        _endShot();
      }
    }
  }

  // For each ball, see if it's inside any pocket sensor. If so, kick
  // off the drop animation and switch its fixture to a sensor so other
  // balls can pass through. The component is removed from the world
  // a moment later when the animation completes.
  void _checkPockets() {
    final pocketRadiusSq = math.pow(_table.pocketRadius * 0.85, 2);
    void checkBall(PoolBall ball) {
      if (ball.potted || !ball.isMounted) return;
      final pos = ball.body.position;
      for (final p in _table.pocketCenters) {
        final dx = pos.x - p.x;
        final dy = pos.y - p.y;
        if (dx * dx + dy * dy < pocketRadiusSq) {
          ball.markPotted(p);
          HapticFeedback.lightImpact();
          break;
        }
      }
    }

    checkBall(_cueBall);
    for (final ball in _objectBalls) {
      checkBall(ball);
    }
  }

  // Advances the drop animation on every potted ball and removes the
  // component once the shrink-and-fade has finished. Object balls are
  // taken out of the world entirely; the cue ball is re-spotted at
  // the head spot during _endShot if it scratched.
  void _tickPottingAnimations(double dt) {
    void tick(PoolBall ball) {
      if (!ball.potted) return;
      ball.tickPottingAnimation(dt);
      if (ball.pottingComplete) {
        // Cue ball is special — _endShot handles the respawn so we
        // don't yank it out of the world here.
        if (!ball.isCueBall && ball.isMounted) {
          ball.removeFromParent();
        }
      }
    }

    tick(_cueBall);
    for (final ball in _objectBalls) {
      tick(ball);
    }
  }

  // Records the first ball the cue ball touches during a shot — only the
  // first one matters for "you must hit your own type first" foul logic.
  // Cushion contacts are ignored; we only care about ball-on-ball.
  void _handleCueContact(Object other) {
    if (other is PoolBall && !other.isCueBall && _firstBallContacted == null) {
      _firstBallContacted = other;
    }
  }

  // Big rule engine — runs once after every shot resolves (all balls at
  // rest). Order of evaluation matches the official BCA-style 8-ball
  // ruleset: 8-ball pots are game-ending and checked first; scratches
  // and bad first contact are fouls; then we figure out type assignment
  // and whether the shooter shoots again.
  void _endShot() {
    _shotInFlight = false;
    final shooter = currentTurn;
    final shooterType = _typeFor(shooter);

    // Tally everything pocketed during this shot.
    final scratched = _cueBall.potted;
    final newlyPotted = <PoolBall>[];
    for (final b in _objectBalls.where((b) => b.potted && !b._counted)) {
      b._counted = true;
      newlyPotted.add(b);
    }
    final eightPotted = newlyPotted.any((b) => b.number == 8);
    final pottedSolids =
        newlyPotted.where((b) => b.ballType == BallType.solid).toList();
    final pottedStripes =
        newlyPotted.where((b) => b.ballType == BallType.stripe).toList();

    // ── 8-ball pot ends the game ──
    if (eightPotted) {
      final clearedOwnType = shooterType != null &&
          _ballsLeftOfType(shooterType) == 0;
      // Sinking the 8-ball before clearing your own balls is an
      // automatic loss. Same if you scratch on the 8-ball shot.
      final lost = !clearedOwnType || scratched;
      gameOver = true;
      onGameOver(lost ? _opponentOf(shooter) : shooter);
      return;
    }

    // ── Scratch (cue ball pocketed) — opponent gets ball-in-hand ──
    if (scratched) {
      // The cue ball was switched to a sensor and faded by the
      // potting animation; respawnAt brings it fully back to life
      // at the head spot in one call.
      _cueBall.respawnAt(Vector2(0, cueSpawnY));
      _passTurn(withBallInHand: true);
      _refreshScores(pottedSolids.length, pottedStripes.length);
      return;
    }

    // ── First-contact foul: hit nothing, or hit the wrong type ──
    var foul = false;
    final firstHit = _firstBallContacted;
    if (firstHit == null) {
      foul = true;
    } else if (shooterType != null) {
      final cleared = _ballsLeftOfType(shooterType) == 0;
      if (cleared) {
        // Once the shooter has cleared their own balls they're shooting
        // for the 8-ball — that has to be the first contact.
        if (firstHit.number != 8) foul = true;
      } else {
        // Otherwise the first contact must be one of the shooter's balls.
        if (firstHit.ballType != shooterType) foul = true;
      }
    }
    // Open table: no first-contact restriction (any non-8 ball is legal).

    if (foul) {
      _passTurn(withBallInHand: true);
      _refreshScores(pottedSolids.length, pottedStripes.length);
      return;
    }

    // ── Open-table type assignment from the first legal pot ──
    if (isTableOpen && newlyPotted.isNotEmpty) {
      if (pottedSolids.isNotEmpty && pottedStripes.isEmpty) {
        _assignTypes(shooter, BallType.solid);
      } else if (pottedStripes.isNotEmpty && pottedSolids.isEmpty) {
        _assignTypes(shooter, BallType.stripe);
      }
      // If both types were potted in the same shot the table stays
      // open and the shooter picks next time by what they pocket.
    }

    // ── Continue or pass turn ──
    final pottedShooterBall = newlyPotted.any((b) {
      final t = _typeFor(shooter);
      if (t != null) return b.ballType == t;
      // Open table: any non-8, non-cue pot counts toward continuing.
      return b.number != 8 && b.number != 0;
    });
    if (!pottedShooterBall) {
      _passTurn(withBallInHand: false);
    }

    _refreshScores(pottedSolids.length, pottedStripes.length);
  }

  // ── helpers ──

  BallType? _typeFor(PoolPlayer p) =>
      p == PoolPlayer.a ? playerAType : playerBType;

  PoolPlayer _opponentOf(PoolPlayer p) =>
      p == PoolPlayer.a ? PoolPlayer.b : PoolPlayer.a;

  int _ballsLeftOfType(BallType t) =>
      _objectBalls.where((b) => !b.potted && b.ballType == t).length;

  void _assignTypes(PoolPlayer shooter, BallType shooterType) {
    if (shooter == PoolPlayer.a) {
      playerAType = shooterType;
      playerBType =
          shooterType == BallType.solid ? BallType.stripe : BallType.solid;
    } else {
      playerBType = shooterType;
      playerAType =
          shooterType == BallType.solid ? BallType.stripe : BallType.solid;
    }
    onTypeAssigned?.call(shooter, shooterType);
  }

  void _passTurn({required bool withBallInHand}) {
    currentTurn = _opponentOf(currentTurn);
    onTurnChanged(currentTurn);
    if (withBallInHand) {
      inputMode = PoolInputMode.ballInHand;
      onInputModeChanged?.call(inputMode);
    }
  }

  // Score in the HUD shows balls each player has pocketed of their own
  // type. We recompute from the table state instead of incrementing,
  // so the count is always self-consistent.
  void _refreshScores(int newSolidsThisShot, int newStripesThisShot) {
    final aType = playerAType;
    final bType = playerBType;
    if (aType != null) {
      scoreA = 7 - _ballsLeftOfType(aType);
    } else {
      scoreA = 0;
    }
    if (bType != null) {
      scoreB = 7 - _ballsLeftOfType(bType);
    } else {
      scoreB = 0;
    }
    onScoreChanged(scoreA, scoreB);
  }

  // ─── aim + shoot ─────────────────────────────────────────

  bool get _canShoot {
    if (gameOver || _shotInFlight) return false;
    // Drag-to-aim is disabled while the cue ball is being placed —
    // the player has to tap to set position first.
    if (inputMode == PoolInputMode.ballInHand) return false;
    // The cue ball's BodyComponent isn't truly ready until both isMounted
    // is true *and* its body has been instantiated by Forge2D. We try
    // touching `body.position` defensively in case of timing oddities.
    if (!_cueBall.isMounted) return false;
    try {
      _cueBall.body.position;
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── ball-in-hand: tap on the table to place the cue ball ──

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (inputMode != PoolInputMode.ballInHand) return;
    if (gameOver) return;
    // Convert the tap position from canvas pixels into world coordinates
    // via the camera, then clamp inside the table playing surface so
    // the player can't drop the cue into a rail or off the table.
    final world = camera.globalToLocal(event.canvasPosition);
    final r = _cueBall.radius;
    final hw = tableWidth / 2 - r;
    final hh = tableHeight / 2 - r;
    final x = world.x.clamp(-hw, hw);
    final y = world.y.clamp(-hh, hh);

    _cueBall.removeFromParent();
    super.world.add(_cueBall);
    _cueBall.respawnAt(Vector2(x.toDouble(), y.toDouble()));
    inputMode = PoolInputMode.aim;
    onInputModeChanged?.call(inputMode);
    HapticFeedback.selectionClick();
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!_canShoot) return;
    final p = event.canvasPosition;
    _aimDragStart = Offset(p.x, p.y);
    _aimDragCurrent = _aimDragStart;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_canShoot || _aimDragCurrent == null) return;
    final d = event.localDelta;
    _aimDragCurrent = _aimDragCurrent! + Offset(d.x, d.y);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    final start = _aimDragStart;
    final current = _aimDragCurrent;
    _aimDragStart = null;
    _aimDragCurrent = null;
    if (!_canShoot || start == null || current == null) return;

    // Pull-the-cue-stick metaphor: drag direction is a vector from the
    // current touch back to where the drag started, ball moves along it.
    final pull = start - current;
    final pullLength = pull.distance;
    final powerRatio = powerRatioForPull(pullLength);
    if (powerRatio <= 0) return; // tiny drag, treat as a stray tap

    final dirX = pull.dx / pullLength;
    final dirY = pull.dy / pullLength;
    _shoot(Vector2(dirX, dirY), powerRatio);
  }

  // power is normalized 0..1. Setting linearVelocity directly avoids
  // mass/impulse math and Box2D's internal velocity clamping — what
  // you tune here is exactly what the cue ball moves at.
  void _shoot(Vector2 direction, double powerRatio) {
    HapticFeedback.mediumImpact();
    _firstBallContacted = null;

    final v = powerRatio * _maxShotVelocity;
    _cueBall.body.linearVelocity = direction * v;
    // Spin scales with linear speed but stays in a visually trackable
    // range — full rolling-without-slipping (v/r) would be too fast to
    // see and just look like a blur.
    _cueBall.body.angularVelocity = v * 1.6;
    _shotInFlight = true;
  }
}

// Visual overlay rendered on top of the world while the player is
// dragging. Reads the game's drag state and the cue ball position to
// draw a dotted aim line in the shot direction plus a cue stick pulled
// back behind the ball — the pull distance scales the cue stick gap so
// you can feel the shot "loading up" before release.
class AimGuide extends Component {
  AimGuide(this.gameRef);

  final EightBallGame gameRef;

  @override
  int get priority => 100;

  @override
  void render(Canvas canvas) {
    final start = gameRef.aimDragStart;
    final current = gameRef.aimDragCurrent;
    if (start == null || current == null) return;
    final cue = gameRef.cueBall;
    if (cue.potted || !cue.isMounted) return;

    final pull = start - current;
    final pullDist = pull.distance;
    final powerRatio = EightBallGame.powerRatioForPull(pullDist);
    if (powerRatio <= 0) return;

    final dirX = pull.dx / pullDist;
    final dirY = pull.dy / pullDist;

    final cuePos = cue.body.position;
    final cx = cuePos.x;
    final cy = cuePos.y;
    final r = cue.radius;

    // Aim line — dotted, white at low power, warm gold at high power so
    // the player feels the shot intensity at a glance.
    final aimColor = Color.lerp(
      Colors.white.withValues(alpha: 0.55),
      const Color(0xFFFFC857),
      powerRatio,
    )!;
    final aimPaint = Paint()
      ..color = aimColor
      ..strokeWidth = 0.007
      ..strokeCap = StrokeCap.round;

    final aimStartX = cx + dirX * (r + 0.006);
    final aimStartY = cy + dirY * (r + 0.006);
    final aimLen = 0.18 + powerRatio * 0.55;

    const dashes = 7;
    for (var i = 0; i < dashes; i++) {
      final t1 = i / dashes;
      final t2 = (i + 0.55) / dashes;
      canvas.drawLine(
        Offset(aimStartX + dirX * aimLen * t1,
            aimStartY + dirY * aimLen * t1),
        Offset(aimStartX + dirX * aimLen * t2,
            aimStartY + dirY * aimLen * t2),
        aimPaint,
      );
    }

    // Cue stick — extends behind the cue ball along the shot axis. The
    // stick's tip pulls further back as power grows, giving a visible
    // "draw-back" cue that the user is loading up the shot.
    final stickGap = 0.014 + powerRatio * 0.075;
    final tipX = cx - dirX * (r + stickGap);
    final tipY = cy - dirY * (r + stickGap);
    const stickLen = 0.55;
    final endX = tipX - dirX * stickLen;
    final endY = tipY - dirY * stickLen;

    // Shaft.
    canvas.drawLine(
      Offset(tipX, tipY),
      Offset(endX, endY),
      Paint()
        ..color = const Color(0xFFD4A574)
        ..strokeWidth = 0.014
        ..strokeCap = StrokeCap.round,
    );
    // White ferrule near the tip — short bright segment so the cue
    // reads as a real cue and not just a line.
    canvas.drawLine(
      Offset(tipX, tipY),
      Offset(tipX - dirX * 0.028, tipY - dirY * 0.028),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.92)
        ..strokeWidth = 0.018
        ..strokeCap = StrokeCap.round,
    );
  }
}

// Per-ball flag tracking whether its pocketing has been counted toward
// a player's score yet. We avoid re-counting when the body is removed
// but `potted` stays true. Implemented as a private extension on
// PoolBall so we don't litter the entity with one-off state.
extension on PoolBall {
  static final _counters = Expando<bool>();
  bool get _counted => _counters[this] ?? false;
  set _counted(bool v) => _counters[this] = v;
}
