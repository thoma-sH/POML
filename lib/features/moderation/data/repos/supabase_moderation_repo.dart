import 'package:first_flutter_app/features/moderation/domain/entities/blocked_user.dart';
import 'package:first_flutter_app/features/moderation/domain/entities/report_reason.dart';
import 'package:first_flutter_app/features/moderation/domain/repos/moderation_repo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Production moderation repo. Calls server-side RPCs (`block_user`,
// `unblock_user`, `report_post`, `report_user`) that must exist in
// Supabase. Reads blocks from the `blocks` table directly — RLS scopes
// the rows to the viewer, so no extra filter is needed here.
class SupabaseModerationRepo implements ModerationRepo {
  final _client = Supabase.instance.client;

  @override
  Future<List<BlockedUser>> getBlockedUsers() async {
    final rows = await _client
        .from('blocks')
        .select('blocked_id, created_at, profile:blocked_id ( username, avatar_url )')
        .order('created_at', ascending: false);
    return rows.map((r) {
      final profile = (r['profile'] as Map<String, dynamic>?) ?? const {};
      return BlockedUser(
        userId: r['blocked_id'] as String,
        username: (profile['username'] as String?) ?? '',
        avatarUrl: profile['avatar_url'] as String?,
        blockedAt: DateTime.parse(r['created_at'] as String),
      );
    }).toList(growable: false);
  }

  @override
  Future<void> blockUser({
    required String userId,
    required String username,
  }) async {
    try {
      await _client.rpc('block_user', params: {'_target_id': userId});
    } catch (e) {
      throw Exception(_friendly(e, 'Could not block user.'));
    }
  }

  @override
  Future<void> unblockUser(String userId) async {
    try {
      await _client.rpc('unblock_user', params: {'_target_id': userId});
    } catch (e) {
      throw Exception(_friendly(e, 'Could not unblock user.'));
    }
  }

  @override
  Future<void> reportPost({
    required String postId,
    required ReportReason reason,
    String? note,
  }) async {
    try {
      await _client.rpc('report_post', params: {
        '_post_id': postId,
        '_reason': reason.wireKey,
        '_note': note,
      });
    } catch (e) {
      throw Exception(_friendly(e, 'Could not submit report.'));
    }
  }

  @override
  Future<void> reportUser({
    required String userId,
    required ReportReason reason,
    String? note,
  }) async {
    try {
      await _client.rpc('report_user', params: {
        '_target_id': userId,
        '_reason': reason.wireKey,
        '_note': note,
      });
    } catch (e) {
      throw Exception(_friendly(e, 'Could not submit report.'));
    }
  }

  @override
  bool isBlocked(String userId) => false;

  String _friendly(Object e, String fallback) {
    if (e is PostgrestException) {
      if (e.code == '42883' || e.message.contains('does not exist')) {
        return 'Moderation is not yet enabled on the server.';
      }
      if (e.message.contains('rate_limited')) {
        return 'Slow down — try again in a moment.';
      }
    }
    return fallback;
  }
}
