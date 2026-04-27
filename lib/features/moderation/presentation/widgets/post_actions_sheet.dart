import 'package:first_flutter_app/features/moderation/data/repos/mock_moderation_repo.dart';
import 'package:first_flutter_app/features/moderation/data/repos/supabase_moderation_repo.dart';
import 'package:first_flutter_app/features/moderation/domain/repos/moderation_repo.dart';
import 'package:first_flutter_app/features/moderation/presentation/widgets/report_sheet.dart';
import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_motion.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/widgets/frost_panel.dart';
import 'package:first_flutter_app/shared/widgets/tap_bounce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// Three-rail action sheet shown from the "..." button on a feed post.
// Surfaces Report Post / Report User / Block User in one place.
// Returns `true` if the user blocked the author so the caller can
// refresh the feed and drop the now-invisible post.
Future<bool> showPostActionsSheet(
  BuildContext context, {
  required String postId,
  required String authorId,
  required String authorUsername,
}) async {
  final repo = _resolveRepo();
  final result = await showModalBottomSheet<_ActionResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (sheetCtx) => _ActionsSheet(
      authorUsername: authorUsername,
      onReportPost: () async {
        Navigator.of(sheetCtx).pop(_ActionResult.none);
        await Future<void>.delayed(AppMotion.short);
        if (context.mounted) {
          await showReportPostSheet(context, repo: repo, postId: postId);
        }
      },
      onReportUser: () async {
        Navigator.of(sheetCtx).pop(_ActionResult.none);
        await Future<void>.delayed(AppMotion.short);
        if (context.mounted) {
          await showReportUserSheet(
            context,
            repo: repo,
            userId: authorId,
            username: authorUsername,
          );
        }
      },
      onBlock: () async {
        final confirmed =
            await _showBlockConfirm(sheetCtx, username: authorUsername);
        if (confirmed != true) return;
        try {
          await repo.blockUser(userId: authorId, username: authorUsername);
          if (sheetCtx.mounted) {
            Navigator.of(sheetCtx).pop(_ActionResult.blocked);
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.surface2,
                behavior: SnackBarBehavior.floating,
                duration: AppMotion.long,
                content: Text(
                  '$authorUsername is blocked',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            );
          }
        } catch (e) {
          if (sheetCtx.mounted) {
            Navigator.of(sheetCtx).pop(_ActionResult.none);
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.surface2,
                behavior: SnackBarBehavior.floating,
                duration: AppMotion.long,
                content: Text(
                  e.toString().replaceFirst('Exception: ', ''),
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            );
          }
        }
      },
    ),
  );
  return result == _ActionResult.blocked;
}

ModerationRepo _resolveRepo() =>
    kDebugMode ? MockModerationRepo() : SupabaseModerationRepo();

enum _ActionResult { none, blocked }

Future<bool?> _showBlockConfirm(
  BuildContext context, {
  required String username,
}) {
  final t = Theme.of(context).textTheme;
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
                Text(
                  'block $username?',
                  style: t.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'they won\'t see your posts and you won\'t see theirs. '
                  'they aren\'t notified.',
                  style: t.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
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
                            'block',
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
        ),
      ),
    ),
  );
}

class _ActionsSheet extends StatelessWidget {
  const _ActionsSheet({
    required this.authorUsername,
    required this.onReportPost,
    required this.onReportUser,
    required this.onBlock,
  });

  final String authorUsername;
  final VoidCallback onReportPost;
  final VoidCallback onReportUser;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SafeArea(
        top: false,
        child: FrostPanel(
          borderRadius: AppSpacing.xl,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ActionRow(
                  icon: PhosphorIconsLight.flag,
                  label: 'report this post',
                  onTap: onReportPost,
                ),
                _ActionRow(
                  icon: PhosphorIconsLight.userMinus,
                  label: 'report $authorUsername',
                  onTap: onReportUser,
                ),
                _ActionRow(
                  icon: PhosphorIconsLight.prohibit,
                  label: 'block $authorUsername',
                  danger: true,
                  onTap: onBlock,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final color = danger ? AppColors.downvote : AppColors.textPrimary;
    return TapBounce(
      scaleTo: 0.97,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md - 2,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: t.bodyMedium?.copyWith(
                  color: color,
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
