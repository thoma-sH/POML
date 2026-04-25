import 'package:first_flutter_app/features/moderation/domain/entities/report_reason.dart';
import 'package:first_flutter_app/features/moderation/domain/repos/moderation_repo.dart';
import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_motion.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/widgets/frost_panel.dart';
import 'package:first_flutter_app/shared/widgets/tap_bounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _Target { post, user }

/// Report a feed post.
Future<bool> showReportPostSheet(
  BuildContext context, {
  required ModerationRepo repo,
  required String postId,
}) =>
    _show(
      context,
      target: _Target.post,
      submit: (reason, note) =>
          repo.reportPost(postId: postId, reason: reason, note: note),
    );

/// Report a user account.
Future<bool> showReportUserSheet(
  BuildContext context, {
  required ModerationRepo repo,
  required String userId,
  required String username,
}) =>
    _show(
      context,
      target: _Target.user,
      username: username,
      submit: (reason, note) =>
          repo.reportUser(userId: userId, reason: reason, note: note),
    );

Future<bool> _show(
  BuildContext context, {
  required _Target target,
  required Future<void> Function(ReportReason, String?) submit,
  String? username,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _ReportSheet(
      target: target,
      submit: submit,
      username: username,
    ),
  );
  return result == true;
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({
    required this.target,
    required this.submit,
    this.username,
  });

  final _Target target;
  final Future<void> Function(ReportReason, String?) submit;
  final String? username;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  ReportReason? _reason;
  final _noteController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _submitting) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.submit(
        reason,
        _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface2,
          behavior: SnackBarBehavior.floating,
          duration: AppMotion.long,
          content: Text(
            'thanks — we\'ll review this within 24 hours.',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final title = widget.target == _Target.post
        ? 'report this post'
        : 'report ${widget.username ?? 'this user'}';
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
                _GrabHandle(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: t.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'pick what fits best. our team reviews reports within 24h.',
                  style: t.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final r in ReportReason.values)
                  _ReasonRow(
                    reason: r,
                    selected: _reason == r,
                    onTap: () => setState(() => _reason = r),
                  ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _noteController,
                  enabled: !_submitting,
                  maxLines: 2,
                  maxLength: 200,
                  style: t.bodySmall?.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'add context (optional)',
                    hintStyle: t.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    counterText: '',
                    contentPadding: const EdgeInsets.all(AppSpacing.sm + 2),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                      borderSide: BorderSide(color: AppColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                      borderSide:
                          BorderSide(color: AppColors.accent, width: 1.2),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _error!,
                    style: t.labelSmall?.copyWith(color: AppColors.downvote),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TapBounce(
                        scaleTo: 0.95,
                        onTap: () => Navigator.of(context).pop(false),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(AppSpacing.md),
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
                      child: AnimatedOpacity(
                        duration: AppMotion.short,
                        opacity: (_reason != null && !_submitting) ? 1.0 : 0.45,
                        child: TapBounce(
                          scaleTo: 0.95,
                          onTap: _submit,
                          child: Container(
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.md),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'submit report',
                                    style: t.labelLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
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
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final ReportReason reason;
  final bool selected;
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
      child: AnimatedContainer(
        duration: AppMotion.short,
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.16)
              : AppColors.surface2,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color:
                selected ? AppColors.accent : AppColors.borderSubtle,
            width: selected ? 1.2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                reason.label,
                style: t.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight:
                      selected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            if (selected)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GrabHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.textDisabled.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
