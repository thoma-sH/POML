import 'package:first_flutter_app/features/feed/domain/entities/feed_post.dart';
import 'package:first_flutter_app/features/feed/domain/repos/feed_repo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Production feed source. Calls the `get_following_feed` Postgres RPC,
// which enforces the no-backlog rule (`p.created_at >= f.created_at`)
// and excludes posts from blocked users. The Dart side just maps each
// returned row through the FeedPost factory.
class SupabaseFeedRepo implements FeedRepo {
  final _client = Supabase.instance.client;

  @override
  Future<List<FeedPost>> getFollowingFeed({
    DateTime? cursor,
    int limit = 20,
  }) async {
    final rows = await _client.rpc(
      'get_following_feed',
      params: {
        '_limit': limit,
        '_cursor': cursor?.toUtc().toIso8601String(),
      },
    );
    if (rows is! List) return const [];
    return rows
        .cast<Map<String, dynamic>>()
        .map(FeedPost.fromRpcRow)
        .toList(growable: false);
  }
}
