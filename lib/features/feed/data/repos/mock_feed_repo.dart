import 'package:first_flutter_app/features/feed/domain/entities/feed_post.dart';
import 'package:first_flutter_app/features/feed/domain/repos/feed_repo.dart';
import 'package:first_flutter_app/features/moderation/data/repos/mock_moderation_repo.dart';

// In-memory feed source used in debug builds and during tests. Reads the
// process-global mock block set so blocking a user actually hides their
// posts in dev — production filtering happens in the SQL itself.
class MockFeedRepo implements FeedRepo {
  @override
  Future<List<FeedPost>> getFollowingFeed({
    DateTime? cursor,
    int limit = 20,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final visible = _mock
        .where((p) => !MockModerationRepo.isUserBlocked(p.authorId))
        .toList(growable: false);
    final filtered = cursor == null
        ? visible
        : visible.where((p) => p.createdAt.isBefore(cursor)).toList();
    return filtered.take(limit).toList();
  }
}

final _now = DateTime.now();
final _mock = <FeedPost>[
  FeedPost(
    postId: 'mock-1',
    authorId: 'mock-author-sarah',
    authorUsername: 'sarah',
    albumId: 'mock-album-sunsets',
    albumTitle: 'Sunsets',
    albumDescription: 'everything golden, nothing else',
    albumColorArgb: 0xFFE08A4D,
    caption: 'Watching the sky melt into the sea.',
    mediaUrl: 'https://picsum.photos/seed/lacuna-sunset-sarah/800/1000',
    mediaType: FeedMediaType.photo,
    locationLabel: 'Rogers, Arkansas',
    fitsCount: 184,
    doesntFitCount: 31,
    savesCount: 12,
    netScore: 153,
    createdAt: _now.subtract(const Duration(hours: 2)),
    aspectRatio: 0.8,
    commentCount: 12,
  ),
  FeedPost(
    postId: 'mock-2',
    authorId: 'mock-author-milo',
    authorUsername: 'milo',
    albumId: 'mock-album-quiet',
    albumTitle: 'Quiet',
    albumDescription: 'rooms with no one in them',
    albumColorArgb: 0xFF6B7A8F,
    caption: 'Found this after closing time.',
    mediaUrl: 'https://picsum.photos/seed/lacuna-quiet-milo/800/800',
    mediaType: FeedMediaType.photo,
    locationLabel: 'Brooklyn, NY',
    fitsCount: 92,
    doesntFitCount: 8,
    savesCount: 6,
    netScore: 84,
    createdAt: _now.subtract(const Duration(hours: 5)),
    aspectRatio: 1.0,
    commentCount: 6,
  ),
  FeedPost(
    postId: 'mock-3',
    authorId: 'mock-author-ivy',
    authorUsername: 'ivy',
    albumId: 'mock-album-mossy',
    albumTitle: 'Mossy',
    albumDescription: 'soft green crawling on stone',
    albumColorArgb: 0xFF6B8E6B,
    caption: 'Older than my grandmother. Probably.',
    mediaUrl: 'https://picsum.photos/seed/lacuna-moss-ivy/1200/800',
    mediaType: FeedMediaType.photo,
    locationLabel: 'Olympic Forest, WA',
    fitsCount: 248,
    doesntFitCount: 12,
    savesCount: 24,
    netScore: 236,
    createdAt: _now.subtract(const Duration(hours: 9)),
    aspectRatio: 1.5,
    commentCount: 24,
  ),
  FeedPost(
    postId: 'mock-4',
    authorId: 'mock-author-jun',
    authorUsername: 'jun',
    albumId: 'mock-album-highway',
    albumTitle: 'Highway',
    albumDescription: 'the road, the windshield, the going',
    albumColorArgb: 0xFF8C6CC4,
    caption: 'No reception for hours. Just road.',
    mediaUrl: 'https://picsum.photos/seed/lacuna-road-jun/800/1230',
    mediaType: FeedMediaType.photo,
    locationLabel: 'Banff, Alberta',
    fitsCount: 412,
    doesntFitCount: 19,
    savesCount: 38,
    netScore: 393,
    createdAt: _now.subtract(const Duration(hours: 14)),
    aspectRatio: 0.65,
    commentCount: 38,
  ),
  FeedPost(
    postId: 'mock-5',
    authorId: 'mock-author-cass',
    authorUsername: 'cass',
    albumId: 'mock-album-coffee',
    albumTitle: 'Coffee',
    albumDescription: 'mug, table, morning light',
    albumColorArgb: 0xFF8B5E3C,
    caption: 'Third refill. Worth it.',
    mediaUrl: 'https://picsum.photos/seed/lacuna-coffee-cass/800/800',
    mediaType: FeedMediaType.photo,
    locationLabel: 'Portland, OR',
    fitsCount: 67,
    doesntFitCount: 41,
    savesCount: 9,
    netScore: 26,
    createdAt: _now.subtract(const Duration(days: 1)),
    aspectRatio: 1.0,
    commentCount: 9,
  ),
];
