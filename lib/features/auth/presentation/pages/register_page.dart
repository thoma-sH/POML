import 'package:first_flutter_app/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:first_flutter_app/features/auth/presentation/cubits/auth_states.dart';
import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_motion.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/utils/url_launch.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Placeholder URLs — keep in sync with settings_page.dart until real ones land.
const _termsUrl = 'https://lacuna.app/terms';
const _privacyUrl = 'https://lacuna.app/privacy';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _agreedToTerms = false;
  bool _showAgreementError = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final formOk = _formKey.currentState!.validate();
    if (!_agreedToTerms) {
      setState(() => _showAgreementError = true);
    }
    if (!formOk || !_agreedToTerms) return;
    context.read<AuthCubit>().register(
          _usernameController.text.trim().toLowerCase(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.of(context).pop();
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Create account')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username is required';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_-]{3,20}$').hasMatch(value)) {
                        return 'Use 3–20 characters: letters, numbers, _ or -';
                      }
                      if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
                        return 'Must contain at least one letter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _AgreementBlock(
                    checked: _agreedToTerms,
                    showError: _showAgreementError && !_agreedToTerms,
                    onChanged: (v) {
                      setState(() {
                        _agreedToTerms = v;
                        if (v) _showAgreementError = false;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      final loading = state is AuthLoading;
                      return FilledButton(
                        onPressed: loading ? null : _submit,
                        child: Text(
                          loading ? 'Creating account...' : 'Create',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgreementBlock extends StatelessWidget {
  const _AgreementBlock({
    required this.checked,
    required this.showError,
    required this.onChanged,
  });

  final bool checked;
  final bool showError;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final borderColor = showError
        ? AppColors.downvote
        : (checked ? AppColors.accent : AppColors.borderSubtle);
    return AnimatedContainer(
      duration: AppMotion.short,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppSpacing.sm + 2),
        border: Border.all(color: borderColor, width: showError ? 1.2 : 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: Checkbox(
                    value: checked,
                    onChanged: (v) => onChanged(v ?? false),
                    activeColor: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _AgreementText(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'lacuna has zero tolerance for objectionable content or abusive '
            'users. reports are reviewed within 24 hours.',
            style: t.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              height: 1.4,
            ),
          ),
          if (showError) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'please agree to continue.',
              style: t.labelSmall?.copyWith(color: AppColors.downvote),
            ),
          ],
        ],
      ),
    );
  }
}

class _AgreementText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final base = t.bodySmall?.copyWith(
      color: AppColors.textSecondary,
      height: 1.4,
    );
    final link = base?.copyWith(
      color: AppColors.accent,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.accent,
    );
    return RichText(
      text: TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'i agree to the '),
          TextSpan(
            text: 'terms of service',
            style: link,
            recognizer: _tap(() => launchExternalUrl(context, _termsUrl)),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'privacy policy',
            style: link,
            recognizer: _tap(() => launchExternalUrl(context, _privacyUrl)),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}

// Tiny helper so we don't need to import gestures.dart at every call site.
TapGestureRecognizer _tap(VoidCallback onTap) =>
    TapGestureRecognizer()..onTap = onTap;
