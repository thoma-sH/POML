import 'package:first_flutter_app/features/game/domain/entities/game_kind.dart';
import 'package:first_flutter_app/features/game/domain/repos/game_repo.dart';
import 'package:first_flutter_app/features/game/presentation/cubits/games_hub_cubit.dart';
import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_motion.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/widgets/frost_panel.dart';
import 'package:first_flutter_app/shared/widgets/tap_bounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Two-step invite sheet: pick a game kind, then pick someone to challenge.
// Returns the new invite id on success so the hub can confirm with a
// snackbar. The friend list comes from the GameRepo so the same code
// path drives both mock and Supabase builds.
Future<String?> showInviteSheet(
  BuildContext context, {
  required GameRepo repo,
  GameKind? presetKind,
}) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (sheetCtx) => BlocProvider.value(
      value: context.read<GamesHubCubit>(),
      child: _InviteSheet(repo: repo, presetKind: presetKind),
    ),
  );
}

class _InviteSheet extends StatefulWidget {
  const _InviteSheet({required this.repo, this.presetKind});

  final GameRepo repo;
  final GameKind? presetKind;

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  late GameKind? _kind = widget.presetKind;
  Future<List<InvitableFriend>>? _friendsFuture;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _friendsFuture = widget.repo.getInvitableFriends();
  }

  Future<void> _submit(InvitableFriend friend) async {
    final kind = _kind;
    if (kind == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _submitting = true;
      _error = null;
    });
    final id = await context.read<GamesHubCubit>().createInvite(
          toUserId: friend.userId,
          kind: kind,
        );
    if (!mounted) return;
    if (id == null) {
      setState(() {
        _submitting = false;
        _error = 'Couldn\'t send the challenge.';
      });
      return;
    }
    Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg + viewInsets,
      ),
      child: SafeArea(
        top: false,
        child: FrostPanel(
          borderRadius: AppSpacing.xl,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textDisabled.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _kind == null ? 'pick a game' : 'pick someone',
                  style: t.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_kind == null)
                  ..._buildKindList()
                else
                  _buildFriendList(),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _error!,
                    style: t.labelSmall?.copyWith(color: AppColors.downvote),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildKindList() {
    return [
      for (final kind in GameKind.values)
        if (kind.isPlayable)
          _KindRow(
            kind: kind,
            onTap: () => setState(() => _kind = kind),
          ),
    ];
  }

  Widget _buildFriendList() {
    return SizedBox(
      height: 320,
      child: FutureBuilder<List<InvitableFriend>>(
        future: _friendsFuture,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final friends = snap.data!;
          if (friends.isEmpty) {
            return Center(
              child: Text(
                'follow someone first to challenge them.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            );
          }
          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: friends.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (_, i) => _FriendRow(
              friend: friends[i],
              enabled: !_submitting,
              onTap: () => _submit(friends[i]),
            ),
          );
        },
      ),
    );
  }
}

class _KindRow extends StatelessWidget {
  const _KindRow({required this.kind, required this.onTap});

  final GameKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return TapBounce(
      scaleTo: 0.97,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color: AppColors.borderSubtle,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kind.displayName,
                    style: t.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    kind.tagline,
                    style: t.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.friend,
    required this.enabled,
    required this.onTap,
  });

  final InvitableFriend friend;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AnimatedOpacity(
      duration: AppMotion.short,
      opacity: enabled ? 1.0 : 0.5,
      child: TapBounce(
        scaleTo: 0.97,
        onTap: enabled ? onTap : () {},
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            border: Border.all(
              color: AppColors.borderSubtle,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface3,
                ),
                alignment: Alignment.center,
                child: Text(
                  friend.username.isEmpty
                      ? '?'
                      : friend.username[0].toUpperCase(),
                  style: t.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  friend.username,
                  style: t.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
