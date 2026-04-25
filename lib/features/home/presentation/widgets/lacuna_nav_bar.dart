import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_motion.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/widgets/glass_surface.dart';
import 'package:first_flutter_app/shared/widgets/scalloped_avatar.dart';
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: SafeArea(
        top: false,
        child: GlassSurface(
          borderRadius: AppRadii.pill,
          thickness: GlassThickness.thick,
          child: SizedBox(
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

  static const double _size = 42;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScallopedOutlineButton(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        size: _size,
        borderColor: AppColors.accent,
        child: Icon(
          PhosphorIconsLight.plus,
          color: AppColors.accent,
          size: 18,
        ),
      ),
    );
  }
}
