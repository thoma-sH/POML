import 'package:first_flutter_app/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:first_flutter_app/features/auth/presentation/widgets/delete_account_sheet.dart';
import 'package:first_flutter_app/features/moderation/presentation/pages/blocked_accounts_page.dart';
import 'package:first_flutter_app/shared/constants/legal_urls.dart';
import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_motion.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/theme/lacuna_theme.dart';
import 'package:first_flutter_app/shared/theme/lacuna_theme_provider.dart';
import 'package:first_flutter_app/shared/theme/theme_variants.dart';
import 'package:first_flutter_app/shared/utils/url_launch.dart';
import 'package:first_flutter_app/shared/widgets/glass_surface.dart';
import 'package:first_flutter_app/shared/widgets/tap_bounce.dart';
import 'package:first_flutter_app/shared/widgets/theme_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Header()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            SliverToBoxAdapter(child: _SectionLabel('account')),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            const SliverToBoxAdapter(child: _AccountSection()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            SliverToBoxAdapter(child: _SectionLabel('privacy & safety')),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            const SliverToBoxAdapter(child: _PrivacySafetySection()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            SliverToBoxAdapter(child: _SectionLabel('appearance')),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            const SliverToBoxAdapter(child: _ThemePicker()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            SliverToBoxAdapter(child: _SectionLabel('support & legal')),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            const SliverToBoxAdapter(child: _SupportLegalSection()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            SliverToBoxAdapter(child: _SectionLabel('danger')),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            const SliverToBoxAdapter(child: _DangerSection()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            const SliverToBoxAdapter(child: _AboutFooter()),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.huge + AppSpacing.xl),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── header ─────────────────────────────────────────────────

class _Header extends StatelessWidget {
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
            'settings',
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

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

// ─── reusable row ───────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: GlassSurface(
        thickness: GlassThickness.regular,
        borderRadius: AppSpacing.md,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.borderSubtle,
                  indent: AppSpacing.md + 28 + AppSpacing.md,
                  endIndent: AppSpacing.md,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.detail,
    this.danger = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? detail;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final color = danger ? AppColors.downvote : AppColors.textPrimary;
    final iconColor = danger ? AppColors.downvote : AppColors.textSecondary;
    return TapBounce(
      scaleTo: 0.98,
      onTap: () {
        if (onTap == null) return;
        HapticFeedback.selectionClick();
        onTap!();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md - 2,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 14),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: t.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail!,
                      style: t.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
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

// ─── account ────────────────────────────────────────────────

class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    return _SettingsGroup(
      children: [
        _SettingsRow(
          icon: PhosphorIconsLight.userCircle,
          label: 'edit profile',
          detail: 'username, mantra, avatar',
          onTap: () => _comingSoon(context, 'edit profile'),
        ),
        _SettingsRow(
          icon: PhosphorIconsLight.bell,
          label: 'notifications',
          detail: 'push, in-app, email',
          onTap: () => _comingSoon(context, 'notifications'),
        ),
        _SettingsRow(
          icon: PhosphorIconsLight.signOut,
          label: 'sign out',
          onTap: () async {
            HapticFeedback.mediumImpact();
            await context.read<AuthCubit>().logout();
          },
        ),
      ],
    );
  }
}

// ─── privacy & safety ───────────────────────────────────────

class _PrivacySafetySection extends StatelessWidget {
  const _PrivacySafetySection();

  @override
  Widget build(BuildContext context) {
    return _SettingsGroup(
      children: [
        _SettingsRow(
          icon: PhosphorIconsLight.userMinus,
          label: 'blocked accounts',
          detail: 'manage who can\'t see or contact you',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BlockedAccountsPage()),
          ),
        ),
        _SettingsRow(
          icon: PhosphorIconsLight.flag,
          label: 'reported content',
          detail: 'review your reports',
          onTap: () => _comingSoon(context, 'reported content'),
        ),
        _SettingsRow(
          icon: PhosphorIconsLight.eyeSlash,
          label: 'who can see your posts',
          detail: 'followers only · everyone',
          onTap: () => _comingSoon(context, 'visibility'),
        ),
        _SettingsRow(
          icon: PhosphorIconsLight.shield,
          label: 'community guidelines',
          onTap: () => _comingSoon(context, 'guidelines'),
        ),
      ],
    );
  }
}

// ─── support & legal ────────────────────────────────────────

class _SupportLegalSection extends StatelessWidget {
  const _SupportLegalSection();

  @override
  Widget build(BuildContext context) {
    return _SettingsGroup(
      children: [
        _SettingsRow(
          icon: PhosphorIconsLight.envelopeSimple,
          label: 'contact support',
          detail: LegalUrls.supportEmail,
          onTap: () => launchMail(
            context,
            LegalUrls.supportEmail,
            subject: 'Lacuna support',
          ),
        ),
        _SettingsRow(
          icon: PhosphorIconsLight.fileText,
          label: 'terms of service',
          detail: LegalUrls.termsOfService,
          onTap: () => launchExternalUrl(context, LegalUrls.termsOfService),
        ),
        _SettingsRow(
          icon: PhosphorIconsLight.lock,
          label: 'privacy policy',
          detail: LegalUrls.privacyPolicy,
          onTap: () => launchExternalUrl(context, LegalUrls.privacyPolicy),
        ),
        _SettingsRow(
          icon: PhosphorIconsLight.scales,
          label: 'licenses',
          detail: 'open source notices',
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'Lacuna',
          ),
        ),
      ],
    );
  }
}

// ─── danger ─────────────────────────────────────────────────

class _DangerSection extends StatelessWidget {
  const _DangerSection();

  @override
  Widget build(BuildContext context) {
    return _SettingsGroup(
      children: [
        _SettingsRow(
          icon: PhosphorIconsLight.trash,
          label: 'delete account',
          detail: 'this cannot be undone',
          danger: true,
          onTap: () => showDeleteAccountSheet(context),
        ),
      ],
    );
  }
}

// ─── about footer ───────────────────────────────────────────

class _AboutFooter extends StatelessWidget {
  const _AboutFooter();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Center(
        child: Text(
          'lacuna · v0.1',
          style: t.labelSmall?.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

void _comingSoon(BuildContext context, String name) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: AppMotion.long,
      backgroundColor: AppColors.surface2,
      behavior: SnackBarBehavior.floating,
      content: Text(
        '$name is coming soon',
        style: TextStyle(color: AppColors.textPrimary),
      ),
    ),
  );
}

// ─── theme picker (kept from previous version) ──────────────

class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LacunaThemeVariant>(
      valueListenable: lacunaThemeNotifier,
      builder: (_, current, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.95,
            children: [
              for (final variant in LacunaThemeVariant.values)
                _ThemeTile(
                  theme: themeFor(variant),
                  isActive: current == variant,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    lacunaThemeNotifier.value = variant;
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.theme,
    required this.isActive,
    required this.onTap,
  });

  final LacunaTheme theme;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = theme.palette;
    final t = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppSpacing.md + 2);
    return TapBounce(
      scaleTo: 0.94,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.short,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: isActive ? p.accent : AppColors.borderSubtle,
            width: isActive ? 1.5 : 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: ThemePreview(theme: theme)),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        if (isActive)
                          Icon(
                            PhosphorIconsFill.check,
                            color: p.accent,
                            size: 16,
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      theme.displayName.toLowerCase(),
                      style: GoogleFonts.getFont(
                        theme.fontName,
                        textStyle: TextStyle(
                          color: p.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.3,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      theme.tagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.labelSmall?.copyWith(
                        color: p.textTertiary,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
