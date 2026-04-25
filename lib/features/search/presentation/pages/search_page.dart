import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/widgets/glass_surface.dart';
import 'package:first_flutter_app/shared/widgets/grain_overlay.dart';
import 'package:first_flutter_app/shared/widgets/scalloped_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  bool _hasQuery = false;

  static const _suggested = <_PersonResult>[
    _PersonResult(
      username: 'mia.s',
      displayName: 'Mia Sato',
      anucal: 8940,
      albumCount: 14,
      avatarColor: Color(0xFF4F6B8A),
    ),
    _PersonResult(
      username: 'theo.k',
      displayName: 'Theo Kim',
      anucal: 4210,
      albumCount: 9,
      avatarColor: Color(0xFF7E5A8C),
    ),
    _PersonResult(
      username: 'sam.r',
      displayName: 'Sam Rowe',
      anucal: 12300,
      albumCount: 22,
      avatarColor: Color(0xFF5C7A56),
    ),
    _PersonResult(
      username: 'june.w',
      displayName: 'June Wu',
      anucal: 3760,
      albumCount: 7,
      avatarColor: Color(0xFF7A5C3A),
    ),
    _PersonResult(
      username: 'cass.v',
      displayName: 'Cass Vidal',
      anucal: 6540,
      albumCount: 11,
      avatarColor: Color(0xFF8C4A3A),
    ),
    _PersonResult(
      username: 'rem.b',
      displayName: 'Rem Bell',
      anucal: 2890,
      albumCount: 5,
      avatarColor: Color(0xFF3A3760),
    ),
    _PersonResult(
      username: 'eli.d',
      displayName: 'Eli Doan',
      anucal: 7120,
      albumCount: 18,
      avatarColor: Color(0xFF4A5568),
    ),
    _PersonResult(
      username: 'nova.p',
      displayName: 'Nova Park',
      anucal: 5300,
      albumCount: 13,
      avatarColor: Color(0xFF5A4A7A),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasQuery) setState(() => _hasQuery = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_PersonResult> get _results {
    if (!_hasQuery) return _suggested;
    final q = _controller.text.toLowerCase();
    return _suggested
        .where(
          (p) =>
              p.username.contains(q) ||
              p.displayName.toLowerCase().contains(q),
        )
        .toList();
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SearchHeader(controller: _controller, hasQuery: _hasQuery),
                const SizedBox(height: AppSpacing.sm),
                if (!_hasQuery) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.sm,
                      0,
                      AppSpacing.md,
                    ),
                    child: Text(
                      'suggested',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: _results.isEmpty
                      ? _EmptyResults(query: _controller.text)
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.huge + AppSpacing.xl,
                          ),
                          itemCount: _results.length,
                          itemBuilder: (_, i) => _PersonTile(person: _results[i]),
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

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.hasQuery,
  });

  final TextEditingController controller;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'find people',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w300,
              letterSpacing: -0.6,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SearchField(controller: controller, hasQuery: hasQuery),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.hasQuery});

  final TextEditingController controller;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      thickness: GlassThickness.regular,
      borderRadius: AppSpacing.md,
      child: SizedBox(
        height: 46,
        child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: Icon(
              PhosphorIconsLight.magnifyingGlass,
              color: AppColors.textTertiary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                hintText: 'username or name',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textDisabled,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (hasQuery)
            GestureDetector(
              onTap: () => controller.clear(),
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Icon(
                  PhosphorIconsLight.x,
                  color: AppColors.textTertiary,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonTile extends StatefulWidget {
  const _PersonTile({required this.person});

  final _PersonResult person;

  @override
  State<_PersonTile> createState() => _PersonTileState();
}

class _PersonTileState extends State<_PersonTile> {
  bool _following = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final p = widget.person;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          ScallopedAvatar(
            size: 48,
            initial: p.displayName[0],
            color: p.avatarColor,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.displayName,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '@${p.username}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      PhosphorIconsFill.sparkle,
                      color: AppColors.accent,
                      size: 10,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _formatAnucal(p.anucal),
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.accent,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _following = !_following);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs + 2,
              ),
              decoration: BoxDecoration(
                color: _following ? AppColors.accentDeep : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.xl),
                border: Border.all(
                  color: _following ? AppColors.accent : AppColors.borderSubtle,
                  width: 0.5,
                ),
              ),
              child: Text(
                _following ? 'following' : 'follow',
                style: textTheme.labelSmall?.copyWith(
                  color: _following ? AppColors.accent : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
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

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIconsLight.userCircleDashed,
            color: AppColors.textDisabled,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'no one found for "$query"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonResult {
  const _PersonResult({
    required this.username,
    required this.displayName,
    required this.anucal,
    required this.albumCount,
    required this.avatarColor,
  });

  final String username;
  final String displayName;
  final int anucal;
  final int albumCount;
  final Color avatarColor;
}
