import 'package:first_flutter_app/features/moderation/data/repos/mock_moderation_repo.dart';
import 'package:first_flutter_app/features/moderation/data/repos/supabase_moderation_repo.dart';
import 'package:first_flutter_app/features/moderation/domain/entities/blocked_user.dart';
import 'package:first_flutter_app/features/moderation/domain/repos/moderation_repo.dart';
import 'package:first_flutter_app/features/moderation/presentation/cubits/blocks_cubit.dart';
import 'package:first_flutter_app/features/moderation/presentation/cubits/blocks_states.dart';
import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/widgets/glass_surface.dart';
import 'package:first_flutter_app/shared/widgets/tap_bounce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class BlockedAccountsPage extends StatelessWidget {
  const BlockedAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BlocksCubit>(
      create: (_) => BlocksCubit(repo: _resolveRepo())..load(),
      child: const _BlockedAccountsView(),
    );
  }

  static ModerationRepo _resolveRepo() =>
      kDebugMode ? MockModerationRepo() : SupabaseModerationRepo();
}

class _BlockedAccountsView extends StatelessWidget {
  const _BlockedAccountsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Header(),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: BlocBuilder<BlocksCubit, BlocksState>(
                builder: (context, state) => switch (state) {
                  BlocksInitial() ||
                  BlocksLoading() => const _LoadingView(),
                  BlocksFailure(:final message) => _ErrorView(
                      message: message,
                      onRetry: () => context.read<BlocksCubit>().load(),
                    ),
                  BlocksLoaded(:final blocked) when blocked.isEmpty =>
                      const _EmptyView(),
                  BlocksLoaded(:final blocked) => _BlockedList(blocked: blocked),
                },
              ),
            ),
          ],
        ),
      ),
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
            'blocked',
            style: t.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w300,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedList extends StatelessWidget {
  const _BlockedList({required this.blocked});

  final List<BlockedUser> blocked;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.huge,
      ),
      itemCount: blocked.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => _BlockedRow(user: blocked[i]),
    );
  }
}

class _BlockedRow extends StatelessWidget {
  const _BlockedRow({required this.user});

  final BlockedUser user;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GlassSurface(
      thickness: GlassThickness.thin,
      borderRadius: AppSpacing.md,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface3,
            ),
            alignment: Alignment.center,
            child: Text(
              user.username.isEmpty ? '?' : user.username[0].toUpperCase(),
              style: t.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              user.username,
              style: t.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ),
          TapBounce(
            scaleTo: 0.92,
            onTap: () {
              HapticFeedback.selectionClick();
              context.read<BlocksCubit>().unblock(user.userId);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs + 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: 0.5,
                ),
              ),
              child: Text(
                'unblock',
                style: t.labelSmall?.copyWith(
                  color: AppColors.textPrimary,
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

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          color: AppColors.accent,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'no one is blocked.',
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(
            color: AppColors.textTertiary,
            fontStyle: FontStyle.italic,
          ),
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
