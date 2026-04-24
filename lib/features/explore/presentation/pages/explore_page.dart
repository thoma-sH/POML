import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/widgets/grain_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  int _sortIndex = 0;

  static const _sorts = ['Hot', 'Top', 'New'];

  static const _trendingAlbums = <_TrendingAlbum>[
    _TrendingAlbum(
      name: 'Beach',
      author: 'mia.s',
      photoCount: 24,
      anucal: 1240,
      color: Color(0xFF4F6B8A),
    ),
    _TrendingAlbum(
      name: 'Concerts',
      author: 'theo.k',
      photoCount: 38,
      anucal: 980,
      color: Color(0xFF7E5A8C),
    ),
    _TrendingAlbum(
      name: 'Roadtrip',
      author: 'sam.r',
      photoCount: 52,
      anucal: 2310,
      color: Color(0xFF5C7A56),
    ),
    _TrendingAlbum(
      name: 'Coffee',
      author: 'june.w',
      photoCount: 17,
      anucal: 745,
      color: Color(0xFF7A5C3A),
    ),
    _TrendingAlbum(
      name: 'Sad',
      author: 'rem.b',
      photoCount: 11,
      anucal: 630,
      color: Color(0xFF3A3760),
    ),
    _TrendingAlbum(
      name: 'Sunsets',
      author: 'cass.v',
      photoCount: 29,
      anucal: 1870,
      color: Color(0xFF8C4A3A),
    ),
    _TrendingAlbum(
      name: 'Vibing',
      author: 'eli.d',
      photoCount: 44,
      anucal: 3100,
      color: Color(0xFF4A5568),
    ),
    _TrendingAlbum(
      name: 'School',
      author: 'zo.m',
      photoCount: 33,
      anucal: 890,
      color: Color(0xFF6B4F8A),
    ),
    _TrendingAlbum(
      name: 'Camping',
      author: 'lee.x',
      photoCount: 21,
      anucal: 560,
      color: Color(0xFF3D6657),
    ),
    _TrendingAlbum(
      name: 'Saved',
      author: 'nova.p',
      photoCount: 8,
      anucal: 420,
      color: Color(0xFF5A4A7A),
    ),
  ];

  // The ExplorePage is a stateful widget that displays a list of trending photo albums.
  // It includes a header, a row of sorting options (Hot, Top, New), and a grid of album tiles.
  // The _sortIndex state variable keeps track of the currently selected sorting option,
  // and the _trendingAlbums list contains hardcoded data for the albums to display.
  // The build method constructs the UI using a Scaffold with a Stack to layer a grain overlay on top of the content.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: [
          const Positioned.fill(child: GrainOverlay()),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _ExploreHeader()),
                SliverToBoxAdapter(
                  child: _SortRow(
                    sorts: _sorts,
                    selectedIndex: _sortIndex,
                    onChanged: (i) {
                      HapticFeedback.selectionClick();
                      setState(() => _sortIndex = i);
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.huge + AppSpacing.xl,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.sm,
                          crossAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 0.92,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _AlbumTile(album: _trendingAlbums[i]),
                      childCount: _trendingAlbums.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// The _ExploreHeader widget displays the title "explore" and an accompanying compass icon at the top of the ExplorePage.
class _ExploreHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        0,
      ),
      child: Row(
        children: [
          Text(
            'explore',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w300,
              letterSpacing: -0.6,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            PhosphorIconsLight.compassRose,
            color: AppColors.accent,
            size: 20,
          ),
        ],
      ),
    );
  }
}

// The _SortRow widget displays a horizontal list of sorting options (e.g., Hot, Top, New) 
// that users can tap to change the sorting of the displayed albums.
class _SortRow extends StatelessWidget {
  const _SortRow({
    required this.sorts,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> sorts;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  // The _SortRow widget displays a horizontal list of sorting options (e.g., Hot, Top, New) 
  // that users can tap to change the sorting of the displayed albums.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        0,
      ),
      child: Row(
        children: List.generate(sorts.length, (i) {
          final isActive = selectedIndex == i;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accentDeep : AppColors.surface1,
                  borderRadius: BorderRadius.circular(AppSpacing.xl),
                  border: Border.all(
                    color: isActive
                        ? AppColors.accent.withValues(alpha: 0.5)
                        : AppColors.borderSubtle,
                    width: 0.5,
                  ),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: (Theme.of(context).textTheme.labelMedium ??
                          const TextStyle())
                      .copyWith(
                        color: isActive
                            ? AppColors.accent
                            : AppColors.textTertiary,
                        fontWeight: isActive
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                  child: Text(sorts[i]),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// The _AlbumTile widget represents a single album in the grid of trending albums.
// It displays the album's name, author, photo count, and anucal score,
// along with a background gradient based on the album's color.
class _AlbumTile extends StatelessWidget {
  const _AlbumTile({required this.album});

  final _TrendingAlbum album;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(album.color, Colors.white, 0.12) ?? album.color,
                  album.color,
                  Color.lerp(album.color, Colors.black, 0.52) ?? album.color,
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xD4000000)],
                stops: [0.3, 1.0],
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppSpacing.xl),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
              child: Text(
                '@${album.author}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.sm,
            right: AppSpacing.sm,
            bottom: AppSpacing.sm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  album.name,
                  style: textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      PhosphorIconsLight.image,
                      color: Colors.white54,
                      size: 11,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${album.photoCount}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      PhosphorIconsFill.sparkle,
                      color: AppColors.accent,
                      size: 11,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _formatAnucal(album.anucal),
                      style: TextStyle(
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
        ],
      ),
    );
  }

  static String _formatAnucal(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// The _TrendingAlbum class is a simple data model that represents a photo album with properties such as 
// name, author, photo count, anucal score, and a color for display purposes.
// It is used to populate the list of trending albums displayed on the ExplorePage.
class _TrendingAlbum {
  const _TrendingAlbum({
    required this.name,
    required this.author,
    required this.photoCount,
    required this.anucal,
    required this.color,
  });

  final String name;
  final String author;
  final int photoCount;
  final int anucal;
  final Color color;
}
