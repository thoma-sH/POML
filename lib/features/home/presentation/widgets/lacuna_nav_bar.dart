import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_motion.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/theme/lacuna_theme.dart';
import 'package:first_flutter_app/shared/theme/lacuna_theme_provider.dart';
import 'package:first_flutter_app/shared/widgets/glass_surface.dart';
import 'package:first_flutter_app/shared/widgets/tap_bounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class LacunaNavBar extends StatelessWidget {
  const LacunaNavBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItem(
      icon: PhosphorIconsLight.house,
      activeIcon: PhosphorIconsFill.house,
      label: 'Home',
    ),
    _NavItem(
      icon: PhosphorIconsLight.compassRose,
      activeIcon: PhosphorIconsFill.compassRose,
      label: 'Explore',
    ),
    _NavItem(icon: null, activeIcon: null, label: 'Post'),
    _NavItem(
      icon: PhosphorIconsLight.heart,
      activeIcon: PhosphorIconsFill.heart,
      label: 'Activity',
    ),
    _NavItem(
      icon: PhosphorIconsLight.user,
      activeIcon: PhosphorIconsFill.user,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Subscribe directly to the theme notifier so the bar repaints the
    // moment a user picks a new variant — without this, AppColors.* are
    // re-read only on the next outer rebuild (e.g. tab switch), which
    // is why theme changes used to lag a navigation cycle.
    return ValueListenableBuilder<LacunaThemeVariant>(
      valueListenable: lacunaThemeNotifier,
      builder: (_, _, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 32,
                spreadRadius: 2,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GlassSurface(
            borderRadius: AppRadii.pill,
            thickness: GlassThickness.thick,
            tintOverride: AppColors.surface1.withValues(alpha: 0.84),
            child: Stack(
              children: [
                SizedBox(
                  height: 60,
                  child: Row(
                    children: List.generate(_items.length, (i) {
                      if (i == 2) {
                        return Expanded(
                          child: _PostButton(onTap: () => onTap(i)),
                        );
                      }
                      return Expanded(
                        child: _NavTile(
                          item: _items[i],
                          isActive: currentIndex == i,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onTap(i);
                          },
                        ),
                      );
                    }),
                  ),
                ),
                // Lit-from-above sheen — fades from a soft white wash at
                // the top to nothing at the equator. Sells the curvature
                // of the glass slab without obscuring the icons below.
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.10),
                            Colors.white.withValues(alpha: 0.00),
                          ],
                          stops: const [0.0, 0.55],
                        ),
                      ),
                    ),
                  ),
                ),
                // Specular gleam — a stretched window-reflection streak
                // a few pixels under the top edge. Brightest in the
                // middle, fading to transparent at both ends so the
                // pill's curve catches a believable highlight.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 3,
                  height: 8,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.18),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.05, 0.5, 0.95],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 1,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.32),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 1,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData? icon;
  final IconData? activeIcon;
  final String label;
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconData = isActive ? item.activeIcon! : item.icon!;
    final color = isActive ? AppColors.textPrimary : AppColors.textTertiary;

    return TapBounce(
      scaleTo: 0.85,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: AppMotion.short,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              iconData,
              key: ValueKey(isActive),
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 5),
          AnimatedOpacity(
            duration: AppMotion.short,
            opacity: isActive ? 1.0 : 0.0,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostButton extends StatelessWidget {
  const _PostButton({required this.onTap});

  final VoidCallback onTap;

  static const double _size = 46;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TapBounce(
        scaleTo: 0.88,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent,
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGlow,
                blurRadius: 18,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 4,
                left: _size * 0.22,
                right: _size * 0.22,
                height: 1.2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Icon(
                PhosphorIconsBold.plus,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
