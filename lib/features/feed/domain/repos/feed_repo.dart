import 'package:first_flutter_app/features/feed/domain/entities/feed_post.dart';

// Contract for the feed data source. Implementations should return the
// chronologically most-recent posts from accounts the viewer follows,
// excluding any posts authored before the follow began (no backlog).
// Pagination is keyset-based on `createdAt`: pass the oldest `createdAt`
// you've seen as `cursor` to fetch the next page.
abstract class FeedRepo {
  Future<List<FeedPost>> getFollowingFeed({
    DateTime? cursor,
    int limit = 20,
  });
}
