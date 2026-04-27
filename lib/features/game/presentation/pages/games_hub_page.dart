import 'package:first_flutter_app/features/game/data/repos/mock_game_repo.dart';
import 'package:first_flutter_app/features/game/data/repos/supabase_game_repo.dart';
import 'package:first_flutter_app/features/game/domain/entities/game_invite.dart';
import 'package:first_flutter_app/features/game/domain/entities/game_kind.dart';
import 'package:first_flutter_app/features/game/domain/entities/game_session.dart';
import 'package:first_flutter_app/features/game/domain/repos/game_repo.dart';
import 'package:first_flutter_app/features/game/presentation/cubits/games_hub_cubit.dart';
import 'package:first_flutter_app/features/game/presentation/cubits/games_hub_states.dart';
import 'package:first_flutter_app/features/game/presentation/pages/game_session_page.dart';
import 'package:first_flutter_app/features/game/presentation/widgets/invite_sheet.dart';
import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_motion.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/widgets/glass_surface.dart';
import 'package:first_flutter_app/shared/widgets/tap_bounce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// The games hub — single entry point reachable from the home feed
// header. Shows pending invites, sessions in progress, and a grid of
// game tiles a user can tap to challenge a friend with.
class GamesHubPage extends StatelessWidget {
  const GamesHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = _resolveRepo();
    return BlocProvider<GamesHubCubit>(
      create: (_) => GamesHubCubit(repo: repo)..load(),
      child: _HubView(repo: repo),
    );
  }

  static GameRepo _resolveRepo() =>
      kDebugMode ? MockGameRepo() : SupabaseGameRepo();
}

class _HubView extends StatelessWidget {
  const _HubView({required this.repo});

  final GameRepo repo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<GamesHubCubit, GamesHubState>(
          builder: (context, state) => switch (state) {
            GamesHubInitial() ||
            GamesHubLoading() => const _LoadingView(),
            GamesHubFailure(:final message) => _ErrorView(
                message: message,
                onRetry: () => context.read<GamesHubCubit>().load(),
              ),
            GamesHubLoaded(:final activeSessions, :final pendingInvites) =>
                _LoadedView(
                  activeSessions: activeSessions,
                  pendingInvites: pendingInvites,
                  repo: repo,
                ),
          },
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.activeSessions,
    required this.pendingInvites,
    required this.repo,
  });

  final List<GameSession> activeSessions;
  final List<GameInvite> pendingInvites;
  final GameRepo repo;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: _Header()),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        if (pendingInvites.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: _SectionLabel(label: 'incoming challenges'),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          SliverToBoxAdapter(
            child: _IncomingInvitesList(invites: pendingInvites),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
        if (activeSessions.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: _SectionLabel(label: 'in progress'),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          SliverToBoxAdapter(
            child: _ActiveSessionsList(sessions: activeSessions),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
        const SliverToBoxAdapter(
          child: _SectionLabel(label: 'pick a game'),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        SliverToBoxAdapter(child: _GameTileGrid(repo: repo)),
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.huge + AppSpacing.xl),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
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
          Text(
            'games',
            style: t.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w300,
              letterSpacing: -0.4,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Text(
              'duel a friend',
              style: t.labelSmall?.copyWith(
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

// ─── incoming invites ──────────────────────────────────────

class _IncomingInvitesList extends StatelessWidget {
  const _IncomingInvitesList({required this.invites});

  final List<GameInvite> invites;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          for (final invite in invites)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _InviteRow(invite: invite),
            ),
        ],
      ),
    );
  }
}

class _InviteRow extends StatelessWidget {
  const _InviteRow({required this.invite});

  final GameInvite invite;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GlassSurface(
      thickness: GlassThickness.regular,
      borderRadius: AppSpacing.md,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.kind.displayName,
                  style: t.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'they want to play',
                  style: t.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          TapBounce(
            scaleTo: 0.92,
            onTap: () async {
              HapticFeedback.lightImpact();
              await context.read<GamesHubCubit>().decline(invite.id);
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(
                'decline',
                style: t.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          TapBounce(
            scaleTo: 0.92,
            onTap: () async {
              HapticFeedback.mediumImpact();
              final sid =
                  await context.read<GamesHubCubit>().accept(invite.id);
              if (sid != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameSessionPage(sessionId: sid),
                  ),
                );
              }
            },
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
                'accept',
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

// ─── active sessions ───────────────────────────────────────

class _ActiveSessionsList extends StatelessWidget {
  const _ActiveSessionsList({required this.sessions});

  final List<GameSession> sessions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          for (final session in sessions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _SessionRow(session: session),
            ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final myTurn = session.currentTurnId == _viewerId();
    return TapBounce(
      scaleTo: 0.97,
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameSessionPage(sessionId: session.id),
          ),
        );
      },
      child: GlassSurface(
        thickness: GlassThickness.regular,
        borderRadius: AppSpacing.md,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.kind.displayName,
                    style: t.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    myTurn ? 'your turn' : 'their turn',
                    style: t.labelSmall?.copyWith(
                      color: myTurn
                          ? AppColors.accent
                          : AppColors.textTertiary,
                      fontWeight: myTurn
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIconsLight.caretRight,
              color: AppColors.textTertiary,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

String _viewerId() =>
    kDebugMode ? MockGameRepo.viewerId : '';

// ─── game tile grid ────────────────────────────────────────

class _GameTileGrid extends StatelessWidget {
  const _GameTileGrid({required this.repo});

  final GameRepo repo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.05,
        children: [
          for (final kind in GameKind.values) _GameTile(kind: kind, repo: repo),
        ],
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.kind, required this.repo});

  final GameKind kind;
  final GameRepo repo;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final playable = kind.isPlayable;
    return AnimatedOpacity(
      duration: AppMotion.short,
      opacity: playable ? 1.0 : 0.55,
      child: TapBounce(
        scaleTo: playable ? 0.95 : 1.0,
        onTap: playable
            ? () async {
                HapticFeedback.selectionClick();
                final id = await showInviteSheet(
                  context,
                  repo: repo,
                  presetKind: kind,
                );
                if (id == null || !context.mounted) return;
                // In debug builds the mock repo auto-accepts and stashes
                // the resulting session id — if it's there, jump straight
                // into the game so devs can play solo end-to-end without
                // waiting on a real opponent.
                final autoSession =
                    MockGameRepo.consumeLastAutoStartedSessionId();
                if (kDebugMode && autoSession != null) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameSessionPage(sessionId: autoSession),
                    ),
                  );
                  if (context.mounted) {
                    context.read<GamesHubCubit>().load();
                  }
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surface2,
                    behavior: SnackBarBehavior.floating,
                    duration: AppMotion.long,
                    content: Text(
                      'challenge sent',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                );
              }
            : () {},
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.circular(AppSpacing.md + 2),
            border: Border.all(
              color: AppColors.borderSubtle,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                _iconFor(kind),
                color: AppColors.accent,
                size: 28,
              ),
              const Spacer(),
              Text(
                kind.displayName.toLowerCase(),
                style: t.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                playable ? kind.tagline : 'coming soon',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconFor(GameKind kind) {
  switch (kind) {
    case GameKind.ticTacToe:
      return PhosphorIconsLight.gridFour;
    case GameKind.eightBall:
      return PhosphorIconsFill.circle;
    case GameKind.friendOrFoe:
      return PhosphorIconsLight.scales;
    case GameKind.fitsOrDoesnt:
      return PhosphorIconsLight.eye;
  }
}

// ─── stateful views ────────────────────────────────────────

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
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            TapBounce(
              scaleTo: 0.92,
              onTap: onRetry,
              child: Text(
                'try again',
                style: t.labelMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
