import 'package:first_flutter_app/features/game/domain/entities/game_session.dart';
import 'package:first_flutter_app/features/game/presentation/cubits/game_session_cubit.dart';
import 'package:first_flutter_app/features/game/presentation/games/eight_ball/components/pool_ball.dart';
import 'package:first_flutter_app/features/game/presentation/games/eight_ball/eight_ball_game.dart';
import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_motion.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/widgets/tap_bounce.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Hosts the Flame Forge2D 8-ball game inside the standard
// `GameSessionPage` frame. Owns the HUD overlay (score per player,
// turn indicator, win banner) and bridges into `GameSessionCubit` to
// record the final winner. Hot-seat for now: both players share this
// device, so we don't need to gate the drag handler by viewer id —
// whoever is holding the phone takes the current turn's shot.
class EightBallWidget extends StatefulWidget {
  const EightBallWidget({
    required this.session,
    required this.viewerId,
    super.key,
  });

  final GameSession session;
  final String viewerId;

  @override
  State<EightBallWidget> createState() => _EightBallWidgetState();
}

class _EightBallWidgetState extends State<EightBallWidget> {
  late final EightBallGame _game;

  // Mirrors of the Flame game's authoritative state, copied via the
  // game's callbacks so this widget can rebuild without poking inside
  // the Flame component tree on every frame.
  PoolPlayer _turn = PoolPlayer.a;
  int _scoreA = 0;
  int _scoreB = 0;
  BallType? _typeA;
  BallType? _typeB;
  PoolInputMode _inputMode = PoolInputMode.aim;
  PoolPlayer? _winner;

  @override
  void initState() {
    super.initState();
    _game = EightBallGame(
      onTurnChanged: (turn) => setState(() => _turn = turn),
      onScoreChanged: (a, b) => setState(() {
        _scoreA = a;
        _scoreB = b;
      }),
      onTypeAssigned: (player, type) => setState(() {
        if (player == PoolPlayer.a) {
          _typeA = type;
          _typeB = type == BallType.solid ? BallType.stripe : BallType.solid;
        } else {
          _typeB = type;
          _typeA = type == BallType.solid ? BallType.stripe : BallType.solid;
        }
      }),
      onInputModeChanged: (mode) => setState(() => _inputMode = mode),
      onGameOver: (winner) {
        HapticFeedback.heavyImpact();
        setState(() => _winner = winner);
        // Record the result to the session cubit so the activity log
        // and Anucal score pick it up. The session player ids decide
        // which Lacuna user the local PoolPlayer corresponds to.
        final winnerId = winner == PoolPlayer.a
            ? widget.session.playerAId
            : widget.session.playerBId;
        context.read<GameSessionCubit>().submitMove(
              newState: {
                'a': _scoreA,
                'b': _scoreB,
                'winner': winner == PoolPlayer.a ? 'a' : 'b',
              },
              winnerId: winnerId,
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The Flame surface fills its parent. We pass a black background
        // so the area outside the felt rail looks like a dim room rather
        // than the page's regular themed background bleeding through.
        Positioned.fill(
          child: ColoredBox(
            color: const Color(0xFF120E08),
            child: GameWidget(game: _game),
          ),
        ),
        // HUD overlay sits above the game. Top: scoreboard. Bottom:
        // hint text or winner banner.
        Positioned(
          top: AppSpacing.md,
          left: AppSpacing.md,
          right: AppSpacing.md,
          child: _Scoreboard(
            scoreA: _scoreA,
            scoreB: _scoreB,
            typeA: _typeA,
            typeB: _typeB,
            currentTurn: _turn,
            winner: _winner,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.lg,
          child: Center(
            child: _winner != null
                ? _WinnerBanner(
                    winner: _winner!,
                    onClose: () => Navigator.of(context).pop(),
                  )
                : _BottomHint(mode: _inputMode),
          ),
        ),
      ],
    );
  }
}

// Thin frosted strip showing both player scores and which one is up.
class _Scoreboard extends StatelessWidget {
  const _Scoreboard({
    required this.scoreA,
    required this.scoreB,
    required this.typeA,
    required this.typeB,
    required this.currentTurn,
    required this.winner,
  });

  final int scoreA;
  final int scoreB;
  final BallType? typeA;
  final BallType? typeB;
  final PoolPlayer currentTurn;
  final PoolPlayer? winner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PlayerSlot(
              label: 'player 1',
              score: scoreA,
              type: typeA,
              isActive: winner == null && currentTurn == PoolPlayer.a,
              isWinner: winner == PoolPlayer.a,
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          Expanded(
            child: _PlayerSlot(
              label: 'player 2',
              score: scoreB,
              type: typeB,
              isActive: winner == null && currentTurn == PoolPlayer.b,
              isWinner: winner == PoolPlayer.b,
              alignRight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerSlot extends StatelessWidget {
  const _PlayerSlot({
    required this.label,
    required this.score,
    required this.type,
    required this.isActive,
    required this.isWinner,
    this.alignRight = false,
  });

  final String label;
  final int score;
  final BallType? type;
  final bool isActive;
  final bool isWinner;
  final bool alignRight;

  // Returns the headline text for this player slot. Until types are
  // assigned both slots show "open"; after the open break each player
  // shows whichever group (solids/stripes) they were assigned.
  String get _typeLabel {
    switch (type) {
      case null:
        return 'open';
      case BallType.solid:
        return 'solids';
      case BallType.stripe:
        return 'stripes';
      case BallType.eightBall:
      case BallType.cue:
        return 'open';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scoreColor = isWinner
        ? AppColors.upvote
        : isActive
            ? AppColors.accent
            : Colors.white.withValues(alpha: 0.85);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        mainAxisAlignment:
            alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!alignRight) _TurnDot(active: isActive),
          if (!alignRight) const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: alignRight
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: t.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.65),
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '· $_typeLabel',
                    style: t.labelSmall?.copyWith(
                      color: type == null
                          ? Colors.white.withValues(alpha: 0.4)
                          : AppColors.accent,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              AnimatedDefaultTextStyle(
                duration: AppMotion.short,
                style: TextStyle(
                  color: scoreColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.4,
                  height: 1.0,
                ),
                child: Text('$score'),
              ),
            ],
          ),
          if (alignRight) const SizedBox(width: AppSpacing.sm),
          if (alignRight) _TurnDot(active: isActive),
        ],
      ),
    );
  }
}

class _TurnDot extends StatelessWidget {
  const _TurnDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.short,
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.accent : Colors.white.withValues(alpha: 0.18),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.55),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
    );
  }
}

// Bottom-screen hint that swaps between "drag to aim" (normal) and
// "tap to place the cue ball" (after a foul). Ball-in-hand mode tints
// to accent so the player notices the input model has changed.
class _BottomHint extends StatelessWidget {
  const _BottomHint({required this.mode});

  final PoolInputMode mode;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final ballInHand = mode == PoolInputMode.ballInHand;
    final text = ballInHand
        ? 'ball in hand — tap to place the cue'
        : 'drag to aim — pull harder to hit harder';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: ballInHand
            ? AppColors.accent.withValues(alpha: 0.85)
            : Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        text,
        style: t.labelSmall?.copyWith(
          color: ballInHand ? Colors.white : Colors.white.withValues(alpha: 0.85),
          letterSpacing: 0.4,
          fontWeight: ballInHand ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _WinnerBanner extends StatelessWidget {
  const _WinnerBanner({required this.winner, required this.onClose});

  final PoolPlayer winner;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final label = winner == PoolPlayer.a ? 'player 1 wins' : 'player 2 wins';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(
          color: AppColors.upvote.withValues(alpha: 0.55),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: t.titleLarge?.copyWith(
              color: AppColors.upvote,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TapBounce(
            scaleTo: 0.92,
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs + 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                'done',
                style: t.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
