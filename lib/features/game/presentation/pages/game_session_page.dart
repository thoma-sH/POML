import 'package:first_flutter_app/features/game/data/repos/mock_game_repo.dart';
import 'package:first_flutter_app/features/game/data/repos/supabase_game_repo.dart';
import 'package:first_flutter_app/features/game/domain/entities/game_kind.dart';
import 'package:first_flutter_app/features/game/domain/entities/game_session.dart';
import 'package:first_flutter_app/features/game/domain/repos/game_repo.dart';
import 'package:first_flutter_app/features/game/presentation/cubits/game_session_cubit.dart';
import 'package:first_flutter_app/features/game/presentation/cubits/game_session_states.dart';
import 'package:first_flutter_app/features/game/presentation/games/eight_ball/eight_ball_widget.dart';
import 'package:first_flutter_app/features/game/presentation/games/tic_tac_toe_game.dart';
import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/widgets/tap_bounce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Generic frame for one in-progress game. Owns the GameSessionCubit,
// renders the header with opponent + game name + forfeit, and swaps in
// the per-kind widget for the body. New games are added by extending
// the switch in `_buildGameBody`.
class GameSessionPage extends StatelessWidget {
  const GameSessionPage({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GameSessionCubit>(
      create: (_) => GameSessionCubit(
        repo: _resolveRepo(),
        sessionId: sessionId,
      ),
      child: const _SessionView(),
    );
  }

  static GameRepo _resolveRepo() =>
      kDebugMode ? MockGameRepo() : SupabaseGameRepo();
}

class _SessionView extends StatelessWidget {
  const _SessionView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<GameSessionCubit, GameSessionState>(
          builder: (context, state) => switch (state) {
            GameSessionLoading() => const _LoadingView(),
            GameSessionFailure(:final message) => _ErrorView(message: message),
            GameSessionActive(:final session) => _ActiveSession(session: session),
          },
        ),
      ),
    );
  }
}

class _ActiveSession extends StatelessWidget {
  const _ActiveSession({required this.session});

  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final viewerId = _viewerId();
    return Column(
      children: [
        _Header(session: session, viewerId: viewerId),
        Expanded(child: _buildGameBody(session, viewerId)),
      ],
    );
  }

  Widget _buildGameBody(GameSession session, String viewerId) {
    switch (session.kind) {
      case GameKind.ticTacToe:
        return TicTacToeGame(session: session, viewerId: viewerId);
      case GameKind.eightBall:
        return EightBallWidget(session: session, viewerId: viewerId);
      case GameKind.friendOrFoe:
      case GameKind.fitsOrDoesnt:
        return const _ComingSoon();
    }
  }
}

// Resolves the current viewer id. In production it's the Supabase user id;
// in debug we use the mock viewer constant so MockGameRepo's bookkeeping
// matches what the UI considers "self."
String _viewerId() {
  if (kDebugMode) return MockGameRepo.viewerId;
  return Supabase.instance.client.auth.currentUser?.id ?? '';
}

class _Header extends StatelessWidget {
  const _Header({required this.session, required this.viewerId});

  final GameSession session;
  final String viewerId;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final canForfeit = session.status == GameStatus.active;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          TapBounce(
            scaleTo: 0.85,
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              child: Icon(
                PhosphorIconsLight.arrowLeft,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.kind.displayName.toLowerCase(),
                  style: t.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'vs opponent',
                  style: t.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          if (canForfeit) _ForfeitButton(),
        ],
      ),
    );
  }
}

class _ForfeitButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TapBounce(
      scaleTo: 0.92,
      onTap: () async {
        HapticFeedback.mediumImpact();
        final confirmed = await _confirmForfeit(context);
        if (confirmed && context.mounted) {
          await context.read<GameSessionCubit>().forfeit();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(
          PhosphorIconsLight.flag,
          color: AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}

Future<bool> _confirmForfeit(BuildContext context) async {
  final t = Theme.of(context).textTheme;
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.surface1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.md + 4),
      ),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'forfeit this game?',
            style: t.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'your opponent will be marked the winner.',
            style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: TapBounce(
                  scaleTo: 0.95,
                  onTap: () => Navigator.of(ctx).pop(false),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.md),
                    ),
                    child: Text(
                      'cancel',
                      style: t.labelLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TapBounce(
                  scaleTo: 0.95,
                  onTap: () => Navigator.of(ctx).pop(true),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.downvote,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.md),
                    ),
                    child: Text(
                      'forfeit',
                      style: t.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return result == true;
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: AppColors.accent,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsLight.sparkle,
              color: AppColors.accent,
              size: 28,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'coming soon',
              style: t.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'we\'re still building this one — check back soon.',
              textAlign: TextAlign.center,
              style: t.bodySmall?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

