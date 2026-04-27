import 'package:first_flutter_app/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_motion.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/widgets/frost_panel.dart';
import 'package:first_flutter_app/shared/widgets/tap_bounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// Two-step destructive flow required by App Store Guideline 5.1.1(v):
// an explanation screen plus a type-the-word confirmation. Returns `true`
// if the user successfully deleted their account, `false` otherwise.
Future<bool> showDeleteAccountSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (sheetContext) => BlocProvider.value(
      value: context.read<AuthCubit>(),
      child: const _DeleteAccountSheet(),
    ),
  );
  return result == true;
}

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  static const _confirmWord = 'DELETE';
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canDelete =>
      _controller.text.trim().toUpperCase() == _confirmWord && !_submitting;

  Future<void> _submit() async {
    if (!_canDelete) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<AuthCubit>().deleteAccount();
      if (mounted) Navigator.of(context).pop(true);
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
                const _GrabHandle(),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.downvote.withValues(alpha: 0.18),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        PhosphorIconsFill.warning,
                        color: AppColors.downvote,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'delete account',
                        style: t.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'this is permanent. your posts, votes, follows, and profile '
                  'will be removed. this cannot be undone.',
                  style: t.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'type $_confirmWord to confirm',
                  style: t.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _controller,
                  enabled: !_submitting,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                  cursorColor: AppColors.downvote,
                  style: t.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 2,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                      borderSide: BorderSide(
                        color: AppColors.borderSubtle,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                      borderSide: BorderSide(
                        color: AppColors.downvote,
                        width: 1.2,
                      ),
                    ),
                    hintText: _confirmWord,
                    hintStyle: t.bodyMedium?.copyWith(
                      color: AppColors.textDisabled,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _error!,
                    style: t.labelSmall?.copyWith(
                      color: AppColors.downvote,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: TapBounce(
                        scaleTo: 0.95,
                        onTap: () => Navigator.of(context).pop(false),
                        child: Container(
                          height: 46,
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
                        opacity: _canDelete ? 1.0 : 0.45,
                        child: TapBounce(
                          scaleTo: 0.95,
                          onTap: _canDelete ? _submit : () {},
                          child: Container(
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.downvote,
                              borderRadius: BorderRadius.circular(AppSpacing.md),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'permanently delete',
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

class _GrabHandle extends StatelessWidget {
  const _GrabHandle();

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
