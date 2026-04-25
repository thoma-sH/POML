import 'package:first_flutter_app/features/auth/domain/entities/app_user.dart';
import 'package:first_flutter_app/features/feed/presentation/widgets/feed_post_card.dart';
import 'package:first_flutter_app/features/feed/presentation/widgets/immersive_feed_tile.dart';
import 'package:first_flutter_app/features/game/presentation/pages/friend_or_foe_page.dart';
import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_motion.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/widgets/frost_panel.dart';
import 'package:first_flutter_app/shared/widgets/tap_bounce.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const double _headerReservedHeight = 52;
const double _navBarReservedHeight = 80;

class HomeFeedPage extends StatefulWidget {
  const HomeFeedPage({required this.user, super.key});

  final AppUser user;

  @override
  State<HomeFeedPage> createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<HomeFeedPage> {
  late final PageController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController()..addListener(_onPageScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onPageScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    final page = _controller.page;
    if (page == null) return;
    final rounded = page.round();
    if (rounded != _currentIndex) setState(() => _currentIndex = rounded);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        MediaQuery.of(context).padding.bottom + _navBarReservedHeight;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            scrollDirection: Axis.vertical,
            physics: const _ImmersivePageScrollPhysics(),
            itemCount: _mockPosts.length,
            itemBuilder: (_, i) => ImmersiveFeedTile(
              post: _mockPosts[i],
              bottomInset: bottomInset,
              headerInset: _headerReservedHeight,
            ),
          ),
          _PageProgressIndicator(
            count: _mockPosts.length,
            current: _currentIndex,
          ),
          AnimatedSlide(
            duration: AppMotion.medium,
            curve: Curves.easeOutCubic,
            offset: _currentIndex == 0 ? Offset.zero : const Offset(0, -0.6),
            child: AnimatedOpacity(
              duration: AppMotion.medium,
              curve: Curves.easeOutCubic,
              opacity: _currentIndex == 0 ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: _currentIndex != 0,
                child: SafeArea(child: _FloatingHeader()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImmersivePageScrollPhysics extends PageScrollPhysics {
  const _ImmersivePageScrollPhysics({super.parent});

  static final SpringDescription _bouncySpring =
      SpringDescription.withDampingRatio(
        mass: 0.5,
        stiffness: 100,
        ratio: 0.85,
      );

  @override
  _ImmersivePageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _ImmersivePageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => _bouncySpring;
}

class _FloatingHeader extends StatelessWidget {
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
        children: [
          FrostPanel(
            borderRadius: AppRadii.pill,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'lacuna',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterDot(label: 'following', active: true),
                const SizedBox(width: AppSpacing.xs),
                _FilterDot(label: 'live', active: false),
              ],
            ),
          ),
          const Spacer(),
          TapBounce(
            scaleTo: 0.85,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FriendOrFoePage(),
              ),
            ),
            child: FrostPanel(
              borderRadius: AppRadii.pill,
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              child: Icon(
                PhosphorIconsLight.gameController,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TapBounce(
            scaleTo: 0.85,
            onTap: () {},
            child: FrostPanel(
              borderRadius: AppRadii.pill,
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              child: Icon(
                PhosphorIconsLight.paperPlaneTilt,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDot extends StatelessWidget {
  const _FilterDot({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: AppMotion.short,
      style: TextStyle(
        color: active ? AppColors.textPrimary : AppColors.textTertiary,
        fontSize: 11,
        fontWeight: active ? FontWeight.w500 : FontWeight.w400,
        letterSpacing: 0.4,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(label),
      ),
    );
  }
}

class _PageProgressIndicator extends StatelessWidget {
  const _PageProgressIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: AppSpacing.xs,
      top: 0,
      bottom: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(count, (i) {
            final isActive = i == current;
            return AnimatedContainer(
              duration: AppMotion.short,
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(vertical: 3),
              width: 2,
              height: isActive ? 18 : 6,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.textPrimary
                    : AppColors.textPrimary.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ),
    );
  }
}

final _mockPosts = <FeedPost>[
  const FeedPost(
    author: 'sarah',
    blobName: 'Sunsets',
    themeDescription: 'everything golden, nothing else',
    caption: 'Watching the sky melt into the sea.',
    location: 'Rogers, Arkansas',
    timeAgo: '2h',
    blobColor: Color(0xFFE08A4D),
    aspectRatio: 0.8,
    fitsCount: 184,
    doesntFitCount: 31,
    commentCount: 12,
    imageUrl: 'https://picsum.photos/seed/lacuna-sunset-sarah/800/1000',
  ),
  const FeedPost(
    author: 'milo',
    blobName: 'Quiet',
    themeDescription: 'rooms with no one in them',
    caption: 'Found this after closing time.',
    location: 'Brooklyn, NY',
    timeAgo: '5h',
    blobColor: Color(0xFF6B7A8F),
    aspectRatio: 1.0,
    fitsCount: 92,
    doesntFitCount: 8,
    commentCount: 6,
    imageUrl: 'https://picsum.photos/seed/lacuna-quiet-milo/800/800',
  ),
  const FeedPost(
    author: 'ivy',
    blobName: 'Mossy',
    themeDescription: 'soft green crawling on stone',
    caption: 'Older than my grandmother. Probably.',
    location: 'Olympic Forest, WA',
    timeAgo: '9h',
    blobColor: Color(0xFF6B8E6B),
    aspectRatio: 1.5,
    fitsCount: 248,
    doesntFitCount: 12,
    commentCount: 24,
    imageUrl: 'https://picsum.photos/seed/lacuna-moss-ivy/1200/800',
  ),
  const FeedPost(
    author: 'jun',
    blobName: 'Highway',
    themeDescription: 'the road, the windshield, the going',
    caption: 'No reception for hours. Just road.',
    location: 'Banff, Alberta',
    timeAgo: '14h',
    blobColor: Color(0xFF8C6CC4),
    aspectRatio: 0.65,
    fitsCount: 412,
    doesntFitCount: 19,
    commentCount: 38,
    imageUrl: 'https://picsum.photos/seed/lacuna-road-jun/800/1230',
  ),
  const FeedPost(
    author: 'cass',
    blobName: 'Coffee',
    themeDescription: 'mug, table, morning light',
    caption: 'Third refill. Worth it.',
    location: 'Portland, OR',
    timeAgo: '1d',
    blobColor: Color(0xFF8B5E3C),
    aspectRatio: 1.0,
    fitsCount: 67,
    doesntFitCount: 41,
    commentCount: 9,
    imageUrl: 'https://picsum.photos/seed/lacuna-coffee-cass/800/800',
  ),
];
