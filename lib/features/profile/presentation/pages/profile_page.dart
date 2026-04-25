import 'package:first_flutter_app/features/activity/presentation/pages/traces_page.dart';
import 'package:first_flutter_app/features/auth/domain/entities/app_user.dart';
import 'package:first_flutter_app/features/settings/presentation/pages/settings_page.dart';
import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/theme/lacuna_theme.dart';
import 'package:first_flutter_app/shared/theme/lacuna_theme_provider.dart';
import 'package:first_flutter_app/shared/widgets/breathing_sparkle.dart';
import 'package:first_flutter_app/shared/widgets/glass_surface.dart';
import 'package:first_flutter_app/shared/widgets/grain_overlay.dart';
import 'package:first_flutter_app/shared/widgets/scalloped_avatar.dart';
import 'package:first_flutter_app/shared/widgets/sparkle_cluster.dart';
import 'package:first_flutter_app/shared/widgets/tap_bounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({required this.user, super.key});

  final AppUser user;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _lacunaLabel = 'Lacuna';
  bool _editingLabel = false;
  late final TextEditingController _labelController;

  static const _avatarColor = Color(0xFF7E5A8C);
  static const _postLacuna = 247;
  static const _gameLacuna = 13;
  static const _followers = '1.2K';
  static const _following = '340';

  int get _totalLacuna => _postLacuna + _gameLacuna;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: _lacunaLabel);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _saveLabel() {
    final trimmed = _labelController.text.trim();
    setState(() {
      if (trimmed.isNotEmpty) _lacunaLabel = trimmed;
      _editingLabel = false;
    });
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: GrainOverlay()),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _TopRail(onSettings: _openSettings)),
                SliverToBoxAdapter(child: _AvatarHero(color: _avatarColor)),
                SliverToBoxAdapter(
                  child: _IdentityBlock(username: widget.user.username),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
                SliverToBoxAdapter(
                  child: _LacunaHero(
                    label: _lacunaLabel,
                    total: _totalLacuna,
                    postLacuna: _postLacuna,
                    gameLacuna: _gameLacuna,
                    onTapLabel: () {
                      HapticFeedback.selectionClick();
                      _labelController.text = _lacunaLabel;
                      setState(() => _editingLabel = true);
                    },
                  ),
                ),
                if (_editingLabel)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.md,
                        AppSpacing.xl,
                        0,
                      ),
                      child: TextField(
                        controller: _labelController,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saveLabel(),
                        onTapOutside: (_) => _saveLabel(),
                        style: Theme.of(context).textTheme.bodyMedium,
                        cursorColor: AppColors.accent,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.lg),
                ),
                const SliverToBoxAdapter(
                  child: _StatPills(
                    followers: _followers,
                    following: _following,
                    albums: '6',
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
                const SliverToBoxAdapter(
                  child: _SectionLabel(label: 'your shelves'),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),
                const SliverToBoxAdapter(child: _AlbumShelf()),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
                const SliverToBoxAdapter(
                  child: _SectionLabel(label: 'recent traces'),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),
                const SliverToBoxAdapter(child: _ActivityLog()),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
                SliverToBoxAdapter(
                  child: _ViewAllTracesLink(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TracesPage(),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.huge + AppSpacing.xl),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewAllTracesLink extends StatelessWidget {
  const _ViewAllTracesLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: TapBounce(
        scaleTo: 0.96,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'see deeper history',
                style: t.labelMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                PhosphorIconsLight.arrowRight,
                color: AppColors.accent,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopRail extends StatelessWidget {
  const _TopRail({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              TapBounce(
                scaleTo: 0.85,
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Icon(
                    PhosphorIconsLight.shareNetwork,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
              TapBounce(
                scaleTo: 0.85,
                onTap: onSettings,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Icon(
                    PhosphorIconsLight.gearSix,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarHero extends StatelessWidget {
  const _AvatarHero({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final isCalm =
        LacunaThemeScope.of(context).variant == LacunaThemeVariant.calm;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: SizedBox(
        height: 196,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            ScallopedAvatar(size: 168, initial: 'T', color: color),
            if (isCalm) ...[
              Positioned(
                top: 4,
                left: MediaQuery.of(context).size.width * 0.18,
                child: BreathingSparkle(
                  color: AppColors.accent,
                  size: 18,
                  duration: const Duration(milliseconds: 5400),
                  phaseOffset: 0.2,
                ),
              ),
              Positioned(
                top: 32,
                right: MediaQuery.of(context).size.width * 0.14,
                child: BreathingSparkle(
                  color: AppColors.accent,
                  size: 12,
                  duration: const Duration(milliseconds: 4600),
                  phaseOffset: 0.65,
                ),
              ),
              Positioned(
                bottom: 8,
                right: MediaQuery.of(context).size.width * 0.22,
                child: BreathingSparkle(
                  color: AppColors.accent,
                  size: 9,
                  duration: const Duration(milliseconds: 5000),
                  phaseOffset: 0.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IdentityBlock extends StatelessWidget {
  const _IdentityBlock({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        0,
      ),
      child: Column(
        children: [
          Text(
            username.toLowerCase(),
            textAlign: TextAlign.center,
            style: textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w300,
              letterSpacing: -0.6,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'capturing quiet moments',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _LacunaHero extends StatelessWidget {
  const _LacunaHero({
    required this.label,
    required this.total,
    required this.postLacuna,
    required this.gameLacuna,
    required this.onTapLabel,
  });

  final String label;
  final int total;
  final int postLacuna;
  final int gameLacuna;
  final VoidCallback onTapLabel;

  String _fmt(int n) => n >= 0 ? '+$n' : '$n';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          Text(
            '$total',
            style: textTheme.displayLarge?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w200,
              letterSpacing: -2.4,
              height: 1.0,
              fontSize: 72,
              shadows: [
                Shadow(
                  color: AppColors.accentGlow,
                  blurRadius: 28,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onLongPress: onTapLabel,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SparkleCluster(color: AppColors.accent, size: 26),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label.toLowerCase(),
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.8,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ScoreBreakdown(label: 'posts', value: _fmt(postLacuna)),
              const SizedBox(width: AppSpacing.lg),
              Container(
                width: 2,
                height: 12,
                color: AppColors.borderSubtle,
              ),
              const SizedBox(width: AppSpacing.lg),
              _ScoreBreakdown(label: 'games', value: _fmt(gameLacuna)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBreakdown extends StatelessWidget {
  const _ScoreBreakdown({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StatPills extends StatelessWidget {
  const _StatPills({
    required this.followers,
    required this.following,
    required this.albums,
  });

  final String followers;
  final String following;
  final String albums;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Pill(value: followers, label: 'followers'),
          const SizedBox(width: AppSpacing.sm),
          _Pill(value: following, label: 'following'),
          const SizedBox(width: AppSpacing.sm),
          _Pill(value: albums, label: 'shelves'),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassSurface(
      thickness: GlassThickness.thin,
      borderRadius: AppRadii.pill,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
              letterSpacing: 0.4,
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

class _Album {
  const _Album({
    required this.name,
    required this.theme,
    required this.color,
    required this.photoCount,
    required this.fitsCount,
  });

  final String name;
  final String theme;
  final Color color;
  final int photoCount;
  final int fitsCount;
}

const _mockAlbums = <_Album>[
  _Album(
    name: 'Sunsets',
    theme: 'everything golden',
    color: Color(0xFFE08A4D),
    photoCount: 24,
    fitsCount: 320,
  ),
  _Album(
    name: 'Quiet',
    theme: 'rooms with no one',
    color: Color(0xFF6B7A8F),
    photoCount: 18,
    fitsCount: 256,
  ),
  _Album(
    name: 'Mossy',
    theme: 'green on stone',
    color: Color(0xFF6B8E6B),
    photoCount: 31,
    fitsCount: 412,
  ),
  _Album(
    name: 'Highway',
    theme: 'the road, the going',
    color: Color(0xFF8C6CC4),
    photoCount: 16,
    fitsCount: 198,
  ),
  _Album(
    name: 'Coffee',
    theme: 'mug, table, light',
    color: Color(0xFF8B5E3C),
    photoCount: 22,
    fitsCount: 89,
  ),
  _Album(
    name: 'Sad',
    theme: 'grey afternoons',
    color: Color(0xFF3A3760),
    photoCount: 11,
    fitsCount: 67,
  ),
];

class _AlbumShelf extends StatelessWidget {
  const _AlbumShelf();

  static const _heights = <double>[140, 168, 124, 156, 132, 148];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: _mockAlbums.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) => Align(
          alignment: Alignment.bottomCenter,
          child: _AlbumCard(
            album: _mockAlbums[i],
            tileHeight: _heights[i % _heights.length],
          ),
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album, required this.tileHeight});

  final _Album album;
  final double tileHeight;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return TapBounce(
      scaleTo: 0.95,
      onTap: () {
        HapticFeedback.selectionClick();
      },
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: tileHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.md),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: album.color),
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              PhosphorIconsLight.image,
                              color: Colors.white70,
                              size: 9,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${album.photoCount}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              album.name.toLowerCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              album.theme,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  PhosphorIconsFill.check,
                  color: AppColors.accent,
                  size: 11,
                ),
                const SizedBox(width: 3),
                Text(
                  '${album.fitsCount} fits',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityEntry {
  const _ActivityEntry({
    required this.icon,
    required this.text,
    required this.timeAgo,
    required this.color,
  });

  final IconData icon;
  final String text;
  final String timeAgo;
  final Color color;
}

const _mockActivity = <_ActivityEntry>[
  _ActivityEntry(
    icon: PhosphorIconsFill.check,
    text: 'voted FITS on sarah\'s sunsets post',
    timeAgo: '12m',
    color: Color(0xFFE08A4D),
  ),
  _ActivityEntry(
    icon: PhosphorIconsLight.bookmarkSimple,
    text: 'saved a post in ivy\'s mossy',
    timeAgo: '1h',
    color: Color(0xFF6B8E6B),
  ),
  _ActivityEntry(
    icon: PhosphorIconsFill.gameController,
    text: 'beat theo.k at chess (+1)',
    timeAgo: '3h',
    color: Color(0xFFB7A6F0),
  ),
  _ActivityEntry(
    icon: PhosphorIconsLight.image,
    text: 'posted to your roadtrip shelf',
    timeAgo: '6h',
    color: Color(0xFF8C6CC4),
  ),
  _ActivityEntry(
    icon: PhosphorIconsLight.x,
    text: 'voted DOESN\'T FIT on cass\'s coffee',
    timeAgo: '1d',
    color: Color(0xFFD17B8E),
  ),
];

class _ActivityLog extends StatelessWidget {
  const _ActivityLog();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: GlassSurface(
        thickness: GlassThickness.regular,
        borderRadius: AppSpacing.md,
        child: Column(
          children: [
            for (var i = 0; i < _mockActivity.length; i++) ...[
              _ActivityRow(entry: _mockActivity[i]),
              if (i < _mockActivity.length - 1)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.borderSubtle,
                  indent: AppSpacing.md,
                  endIndent: AppSpacing.md,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});

  final _ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: entry.color.withValues(alpha: 0.16),
            ),
            alignment: Alignment.center,
            child: Icon(entry.icon, color: entry.color, size: 13),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              entry.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            entry.timeAgo,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
